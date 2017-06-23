require 'money'

#
# Basket  lifecycle:
# ==================
#
#                               +------------------------------+
#                               |                              |
#                          *    |                              V
#    ^open^ ---> checkout ---> paid ------> confirmed ---> !delivered!
#       |           |          |  ∆           ∆  |
#       V           |          |  |           |  |
#  !forgotten! <----+          |  +--> hold --+  |
#                              |        |        |
#  !cancelled! <---------------+--------+--------+
#
# To reopen a basket, the current basket must be cancelled and a new one created
#
# (*) All change to states should be done through .checkout!, .hold!, ... except
#     for to go from checkout to paid status where it's done through receive_payment
#
# In case of an error on a transaction, the transaction_id is saved, the status is
# not changed and the flag "paypal_attention" is set

class Basket < ActiveRecord::Base
  extend FormatApi

  belongs_to :shop
  belongs_to :user
  has_many :basket_items
  belongs_to :basket_payment
  has_many :histories, :class_name => 'BasketHistory'

  after_save :store_basket_history, :notif_status_changed

  define_format_api :public => [:id, :reference, :user_nickname, :nb_items, :status, :total_formated, :paypal_order_date, :reference, :shop_name, :shop_picture],
    :detailed => [:user_picture, :paypal_attention, :paypal_capture_id, :paypal_order_id, :shop_fullpermalink],
    :items => [:basket_items]
  define_api_searchable_attributes %w(shop_id status user_id paypal_order_date)

  def is_private_for? opts
    return self.shop.is_private_for?(opts) || (self.user && self.user.is_private_for?(opts))
  end

  def is_reachable_for? opts
    return self.is_private_for? opts
  end

  def shop_fullpermalink
    return "#{self.shop.fullpermalink(:locale)}/care/basket/#{self.reference(true)}"
  end

  def customer_fullpermalink
    return "#{HtmlHelper.find_root_for(user)}settings/orders/#{self.reference(true)}"
  end

  def customer_permalink
    return "/settings/orders/#{self.reference(true)}"
  end

  def nb_items
    basket_items.count
  end

  def subtotal
    if basket_items.count > 0 then
      basket_items.map(&:line_price_before_tax).sum
    else
      return Money.new(0, shop.currency)
    end
  end

  def user_nickname
    return user.nickname rescue nil
  end

  def user_picture
    return user.picture rescue User::NO_PICTURE
  end

  def shop_name
    return shop.name rescue nil
  end

  def shop_picture
    return shop.user_proxy.picture rescue User::NO_PICTURE
  end


  def tax_amount
    basket_items.map(&:line_tax_amount).sum
  end

  def shipping_amount
    return Money.new(0, shop.currency)
  end

  def total
    if basket_items.count > 0 && basket_items.map(&:line_price_after_tax).sum != 0 then
      return self.shipping_amount + basket_items.map(&:line_price_after_tax).sum
    else
      return Money.new(0, shop.currency) + self.shipping_amount
    end
  end

  def total_formated
    self.total.format
  end

  def estimated_paypal_fees
    self.total * 0.029 + Money.new(30, 'USD')
  end

  def checkout!
    #TODO: Save prices and currency
    return if self.status == 'checkout'
    raise DBArgumentError.new "Basket cannot be frozen" unless ['open'].include? self.status
    self.status='checkout'
    self.save!
  end

  def checkout_url
    return self.class.checkout_list([self])
  end

  #This method should not be called directly, unless to change basket status from 'hold'
  def paid!
    return if self.status == 'paid'
    raise DBArgumentError.new "Basket cannot be paid" unless ['checkout', 'hold'].include? self.status
    raise DBArgumentError.new "Basket does not have a paypal_order_id, thus cannot be paid" if self.paypal_order_id.nil?
    self.status='paid'
    self.save!
  end

  def hold!
    return if self.status == 'hold'
    raise DBArgumentError.new "Basket cannot be put on hold" unless ['paid'].include? self.status
    self.status='hold'
    self.save!
  end

  def cancel!
    return if self.status == 'cancelled'
    raise DBArgumentError.new "Basket requires attention on paypal" if self.paypal_attention
    raise DBArgumentError.new "Basket cannot be cancelled" unless ['open', 'checkout', 'paid', 'hold', 'confirmed'].include? self.status
    if ['open', 'checkout'].include? self.status then
      self.status='forgotten'
    else
      if refund!
        self.status='cancelled'
      end
    end
    self.save!
  end

  def deliver!
    return if self.status == 'delivered'
    raise DBArgumentError.new "Basket requires attention on paypal" if self.paypal_attention
    raise DBArgumentError.new "Basket cannot be delivered" unless ['paid', 'confirmed'].include? self.status
    self.status='delivered'
    self.save!
  end

  def confirm!
    return if self.status == 'confirmed'
    raise DBArgumentError.new "Basket requires attention on paypal" if self.paypal_attention
    raise DBArgumentError.new "Basket cannot be confirmed" unless ['paid', 'hold'].include? self.status
    if capture!
      self.status='confirmed'
      self.save!
    end
  end

  def attention!
    self.paypal_attention = true
    self.save!
  end

  def reopen!(args={})
    return self if self.status == 'open'
    raise DBArgumentError.new "Basket cannot be reopened" unless self.status == 'checkout'

    if args[:except].nil? then
      item_exceptions = []
    elsif args[:except].is_a? Array then
      item_exceptions = args[:except]
    else
      item_exceptions = [args[:except]]
    end

    Basket.transaction do
      new_basket = self.clone
      new_basket.send :status=, 'open'
      new_basket.basket_payment = nil
      new_basket.save!
      self.basket_items.each do |item|
        next if item_exceptions.include?(item)
        new_item = item.clone
        new_item.basket_id = new_basket.id
        new_item.save!
      end
      new_basket
    end
  end

  def delete
    cancel!
  end

  def destroy
    cancel!
  end

  def note_from_shop=val
    raise DBArgumentError.new "Cannot change the note once confirmed" unless ['paid', 'hold'].include?(self.status)
    if val.blank?
      write_attribute(:note_from_shop, nil)
    else
      write_attribute(:note_from_shop, val)
    end
  end

  def comment=val
    raise DBArgumentError.new "Cannot change the comment once checked out" unless self.status == 'open'
    if val.blank?
      write_attribute(:comment, nil)
    else
      write_attribute(:comment, val)
    end
  end

  def basket_payment_id=val
    raise DBArgumentError.new "Cannot change the payment id once paid" unless self.status == 'checkout'
    if val.blank?
      write_attribute(:basket_payment_id, nil)
    else
      write_attribute(:basket_payment_id, val)
    end
  end

  def basket_capture_id=val
    raise DBArgumentError.new "Cannot change the capture id once confirmed" unless self.status == 'paid'
    if val.blank?
      write_attribute(:basket_payment_id, nil)
    else
      write_attribute(:basket_payment_id, val)
    end
  end

  def store_basket_history
    if self.changed_attributes['status'] then
      BasketHistory.create :basket_id => self.id,
        :new_status => self.status,
        :detail => self.changes.to_json
    end
  end

  def notif_status_changed
    old_status = self.changed_attributes['status']
    Rails.logger.debug "Mailing status changed? #{old_status} #{self.status}"
    return if old_status == self.status
    return if old_status.nil? #this should only happen with status=open, but it happens a lot more, causing double mails sent
    if ['paid'].include?(self.status) then
      #mail shop of changed status
      self.shop.owners.each do |user|
        begin
          NotifyShop.notify_basket_status(user, self).deliver
        rescue
          Rails.logger.warn $!.message
          Rails.logger.debug $!.backtrace.join "\n"
        end
      end
    elsif ['confirmed', 'hold', 'delivered'].include?(self.status) then
      #mail user of changed status
      begin
        NotifyUser.notify_basket_status(self.user, self).deliver
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    elsif self.status == 'cancelled' then
      #mail user and shop
      begin
        NotifyUser.notify_basket_status(self.user, self).deliver
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end

      self.shop.owners.each do |user|
        begin
          NotifyShop.notify_basket_status(user, self).deliver
        rescue
          Rails.logger.warn $!.message
          Rails.logger.debug $!.backtrace.join "\n"
        end
      end
    end
  end

  def shaken_id
    "T#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "T"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end



  def reference(force=false)
    return nil if !force && ['open', 'checkout', 'forgotten'].include?(self.status)
    return "BP-#{Mp.shake shop.id, :base => 35}-#{created_at.strftime("%y%m%d")}-#{Mp.shake self.id, :base => 35}"
  end

  def self.decode_reference(ref)
    elts = ref.split('-')
    raise DBArgumentError.new "Invalid reference" unless elts.length == 4
    raise DBArgumentError.new "Invalid reference type" unless elts[0] == 'BP'
    raise DBArgumentError.new "Invalid reference time" unless elts[2].match(/^[0-9]*$/)

    shop_id = Mp.deshake(elts[1].upcase, :base => 35)
    Rails.logger.debug "Looking for shop with ref #{shop_id}"
    shop = Shop.find(shop_id)

    basket_id = Mp.deshake(elts[3].upcase, :base => 35)
    Rails.logger.debug "Looking for basket with ref #{basket_id}"
    basket = Basket.find(basket_id)

    raise DBArgumentError.new "Shop does not match basket" unless basket.shop == shop

    return basket
  end


private
  def status=val
    raise DBArgumentError.new "Invalid status" unless ['open', 'checkout', 'paid', 'hold', 'confirmed', 'forgotten', 'cancelled', 'delivered'].include? self.status
    write_attribute(:status, val)
  end






  ##
  ## PAYPAL INTERACTIONS
  ##
  #
  # 1. Call to SetExpressCheckout : initiates the checkout on paypal for a list of baskets,
  #    returns a checkout token which is used to redirect the buyer to paypal checkout form.
  # 2. .....
  # 3. Call to DoExpressCheckout : assigns a transaction ID to each basket
  # 4. Not done: call to DoAuthorization : locks the money for 3 days
  # 5. When the shop confirms: call to DoCapture: make the money transfer
private

  def self.do_paypal_call request
    request_parameters = {
      'VERSION' => '98.0',
      'USER' => Rails.application.config.paypal[:api_username],
      'PWD' => Rails.application.config.paypal[:api_password],
      'SIGNATURE' => Rails.application.config.paypal[:api_signature]
    }
    request.each do |k,v| request_parameters[k]=v end

    request_string = request_parameters.map do |k,v| "#{url_encode(k)}=#{url_encode(v)}" end .join "&"
    Rails.logger.info "PAYPAL REQUEST : #{request_string}"

    #Making the call
    uri = URI.parse(URI.escape('https://'+Rails.application.config.paypal[:api_3t_host]+'/nvp'))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.post(uri.path, request_string)
    Rails.logger.info "PAYPAL RESPONSE : #{response.body}"

    data = {}
    response.body.split("&").each do |nvp|
      nvp_splitted = nvp.split("=")
      data[CGI::unescape(nvp_splitted[0])] = CGI::unescape(nvp_splitted[1])
    end

    #Log and return Paypal error message if the call failed
    if data['ACK'] != 'Success' then
      if data['L_LONGMESSAGE0'] then
        data.each do |k,v|
          Rails.logger.error "Error returned by Paypal : #{v}" if k.match /L_LONGMESSAGE[0-9]*/
        end
        raise data["L_LONGMESSAGE0"]
      end
      raise DBTechnicalError.new 'Call to Paypal was not successful'
    end

    return data
  end

  def self.checkout_list(baskets)

    #Some Sanity checks to use PAYPAL API easily
    uids = baskets.map(&:user_id).uniq
    raise DBArgumentError.new "All paid baskets must belong to the same user" unless uids.length == 1
    user_id = uids.first


    baskets.each do |basket|
      raise DBArgumentError.new "Shop must have a paypal_id to sell stuff" if basket.shop.paypal_id.blank?
    end

    currencies = baskets.map do |b| b.total.currency_as_string end .uniq
    raise DBArgumentError.new "All paid baskets must have the same currency" unless currencies.length == 1


    #todo : basket sanity checks
    baskets.each do |basket|
      raise DBArgumentError.new "Asking to pay a negative amount" if basket.total.to_f < 0
    end

    #OK, let's lock the baskets for checkout
    baskets.each &:checkout!

    begin
      request = build_paypal_pay_detail(baskets)
      request['METHOD'] = 'SetExpressCheckout'
      request['RETURNURL'] = "#{HtmlHelper.find_root_for(:locale).chop}/api/paypal/basket_return?c=success"
      request['CANCELURL'] = "#{HtmlHelper.find_root_for(:locale).chop}/api/paypal/basket_return?c=cancel"
      request['NOSHIPPING'] = 1 #no shipping.... yet :)
      request['ALLOWNOTE'] = 0 #no note can be added by the customer on paypal
      request['SOLUTIONTYPE'] = 'Sole' # no need of a paypal account to pay
      #request['REQCONFIRMSHIPPING'] = 1  #not sure what a confirmed shipping address is...
      #request['NOTETOBUYER'] = '' #may be useful someday to add a note on the paypal pages

      data = do_paypal_call request

      return Rails.application.config.paypal[:api_3t_url] + "?cmd=_express-checkout&token=#{data['TOKEN']}" if data['TOKEN']

    rescue
      Rails.logger.error "Error while calling Paypal : #{$!.message}"
      Rails.logger.debug $!.backtrace.join("\n")
      raise DBTechnicalError.new "Error while calling Paypal", message: $!.message
    end

  end


  def capture!
    raise DBTechnicalError.new "Impossible to capture a payment that has not been made" unless self.paypal_auth_id||self.paypal_order_id

    begin
      capture = self.class.do_paypal_call 'METHOD' => 'DoCapture', 'SUBJECT' => self.shop.paypal_id, 'AUTHORIZATIONID' => self.paypal_auth_id||self.paypal_order_id, 'AMT' => total.to_s, 'CURRENCYCODE' => total.currency_as_string, 'COMPLETETYPE' => 'Complete'
    rescue
      self.check_status!
      raise $!
    end


    self.paypal_capture_id = capture["TRANSACTIONID"]
    self.paypal_capture_date = Time.now
    self.save!

    status = capture["PAYMENTSTATUS"]
    reason = capture["PENDINGREASON"]
    r_code = capture["REASONCODE"]

    if status != 'Completed' then
      self.attention!
      self.paypal_issue = "DoCapture '#{self.paypal_auth_id||self.paypal_order_id}' => #{status} / #{reason} / #{r_code}"
      self.save!
      self.check_status!
      if status != 'Pending' then
        NotificationHelper.mail_background_exception (DBArgumentError.new "Unexpected response for basket", id: self.id, to: self.paypal_issue)
      end
      return false
    end

    return true
  end

  def refund!
    if paypal_capture_id then
      begin
        refund = self.class.do_paypal_call 'METHOD' => 'RefundTransaction', 'SUBJECT' => self.shop.paypal_id, 'TRANSACTIONID' => self.paypal_capture_id, 'REFUNDTYPE' => 'Full'
      rescue
        self.check_status!
        raise $!
      end

      status = refund['REFUNDSTATUS']
      if status != 'Instant' then
        self.attention!
        self.paypal_issue = "RefundTransaction '#{paypal_capture_id}' => #{status}"
        self.save!
        self.check_status!
        NotificationHelper.mail_background_exception (DBArgumentError.new "Unexpected response for basket", id: self.id, to: self.paypal_issue)
        return false
      end

      self.paypal_refund_id = refund["REFUNDTRANSACTIONID"]
      self.paypal_refund_date = Time.now
      self.save!
    elsif paypal_order_id then
      begin
        refund = self.class.do_paypal_call 'METHOD' => 'DoVoid', 'SUBJECT' => self.shop.paypal_id, 'AUTHORIZATIONID' => self.paypal_order_id
      rescue
        self.check_status!
        raise $!
      end
      self.paypal_refund_date = Time.now
      self.save!
    end

    return true
  end

  def self.build_paypal_pay_detail(baskets, options = {})
    request = {}

    baskets.each_with_index do |basket, basket_idx|
      shop = basket.shop
      request["PAYMENTREQUEST_#{basket_idx}_NOTIFYURL"] = "#{ROOT_URL}api/paypal/basket_ipn" if options[:with_notify_url]
      request["PAYMENTREQUEST_#{basket_idx}_AMT"] = basket.total.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
      request["PAYMENTREQUEST_#{basket_idx}_CURRENCYCODE"] = basket.total.currency_as_string
      request["PAYMENTREQUEST_#{basket_idx}_SHIPPINGAMT"] = basket.shipping_amount.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
      #request["PAYMENTREQUEST_#{basket_idx}_DESC"] = 'Something bought on Diveboard'[0..126]
      request["PAYMENTREQUEST_#{basket_idx}_PAYMENTACTION"] = 'Authorization'
      request["PAYMENTREQUEST_#{basket_idx}_SELLERPAYPALACCOUNTID"] = basket.shop.paypal_id
      request["PAYMENTREQUEST_#{basket_idx}_PAYMENTREQUESTID"] = "#{basket.id}-#{Time.now.to_i}"
      if !shop.price_ref_incl_tax then
        request["PAYMENTREQUEST_#{basket_idx}_ITEMAMT"] = basket.subtotal.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
        request["PAYMENTREQUEST_#{basket_idx}_TAXAMT"] = basket.tax_amount.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
      else
        request["PAYMENTREQUEST_#{basket_idx}_ITEMAMT"] = (basket.subtotal + basket.tax_amount).format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
      end

      basket.basket_items.each_with_index do |item, item_idx|
        request["L_PAYMENTREQUEST_#{basket_idx}_NAME#{item_idx}"] = item.good_to_sell.title
        request["L_PAYMENTREQUEST_#{basket_idx}_QTY#{item_idx}"] = item.quantity
        #request["L_PAYMENTREQUEST_#{basket_idx}_DESC#{item_idx}"] = ????

        if !shop.price_ref_incl_tax then
          request["L_PAYMENTREQUEST_#{basket_idx}_AMT#{item_idx}"] = item.price_before_tax.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
          request["L_PAYMENTREQUEST_#{basket_idx}_TAXAMT#{item_idx}"] = item.tax_amount.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
        else
          request["L_PAYMENTREQUEST_#{basket_idx}_AMT#{item_idx}"] = item.price_after_tax.format(:symbol => nil, :decimal_mark => ".", :thousands_separator => '')
        end
      end
    end

    return request
  end

public

  def self.receive_payment(paypal_token)
    checkout_details = do_paypal_call 'METHOD' => 'GetExpressCheckoutDetails', 'TOKEN' => paypal_token

    baskets = []

    checkout_details.each do |k,v|
      matched = k.match /^PAYMENTREQUEST_([0-9*])_PAYMENTREQUESTID$/
      if matched then
        paymentrequest_position = matched[1].to_i
        basket_id = v.split('-')[0]
        basket = Basket.find(basket_id)
        raise DBArgumentError.new "Basket already paid" if basket.paypal_order_id || basket.paypal_auth_id || basket.paypal_capture_id
        baskets[paymentrequest_position] = basket
      end
    end

    payer_id = checkout_details['PAYERID']

    raise DBArgumentError.new "Unknown payer id" if payer_id.blank?

    currencies = baskets.map do |b| b.total.currency_as_string end .uniq
    raise DBArgumentError.new "All paid baskets must have the same currency" unless currencies.length == 1

    payment_request = build_paypal_pay_detail baskets, :with_notify_url => true
    payment_request['METHOD'] = 'DoExpressCheckoutPayment'
    payment_request['TOKEN'] = paypal_token
    payment_request['PAYERID'] = payer_id

    payment_details = do_paypal_call payment_request

    Basket.transaction do
      baskets.each_with_index do |basket, idx|
        status = payment_details["PAYMENTINFO_#{idx}_PAYMENTSTATUS"]
        reason = payment_details["PAYMENTINFO_#{idx}_PENDINGREASON"]
        r_code = payment_details["PAYMENTINFO_#{idx}_REASONCODE"]
        transaction = payment_details["PAYMENTINFO_#{idx}_TRANSACTIONID"]
        if status  != 'Pending' ||  reason != 'authorization' then
          basket.attention!
          basket.paypal_issue = "DoPayment '#{transaction}' => #{status} / #{reason} / #{r_code}"
          basket.save!
          basket.check_status!
          NotificationHelper.mail_background_exception (DBArgumentError.new "Unexpected response for basket", id: basket.id, to: basket.paypal_issue)
        end
        raise DBTechnicalError.new "No transaction ID provided" if transaction.blank?
        basket.paypal_order_id = transaction
        basket.paypal_order_date = payment_details["PAYMENTINFO_#{idx}_ORDERTIME"] || Time.now
        basket.save!
        basket.paid! unless basket.status == 'attention'
      end
    end
    return baskets
  end


  def check_status!

    order_status = nil
    order_reason = nil
    order_r_code = nil

    capture_status = nil
    capture_reason = nil
    capture_r_code = nil


    if self.paypal_order_id then
      updates = self.class.do_paypal_call 'METHOD' => 'GetTransactionDetails', 'TRANSACTIONID' => self.paypal_order_id, 'SUBJECT' => self.shop.paypal_id
      order_status = updates["PAYMENTSTATUS"]
      order_reason = updates["PENDINGREASON"]
      order_r_code = updates["REASONCODE"]
    end

    if self.paypal_capture_id then
      updates = self.class.do_paypal_call 'METHOD' => 'GetTransactionDetails', 'TRANSACTIONID' => self.paypal_capture_id, 'SUBJECT' => self.shop.paypal_id
      capture_status = updates["PAYMENTSTATUS"]
      capture_reason = updates["PENDINGREASON"]
      capture_r_code = updates["REASONCODE"]
    end

    #Cf paypal_status_for_ipn.xls in dropbox folder
    if self.paypal_order_id.nil? && self.paypal_capture_id.nil? then
      if self.status == "checkout" then
        self.paypal_attention = false
        self.paypal_issue = nil
        self.save!
      else
        self.attention!
        raise DBTechnicalError.new "BIG BUG"
      end
    elsif self.paypal_order_id.nil? && !self.paypal_capture_id.nil? then
      self.attention!
      raise DBTechnicalError.new "BIG BUG"
    elsif self.paypal_capture_id.nil? && ['confirmed', 'delivered'].include?(self.status) then
      self.attention!
      raise DBTechnicalError.new "BIG BUG"
    elsif self.paypal_capture_id.nil? && ['Voided', 'Expired'].include?(order_status) then
      self.paypal_attention = false
      self.paypal_issue = nil
      self.status = 'cancelled'
      self.save!
    elsif self.paypal_capture_id.nil? && ['Reversed', 'Denied', 'Failed', 'Refunded'].include?(order_status) then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'cancelled'
      self.save!
    elsif self.paypal_capture_id.nil? && ['Processed'].include?(order_status) then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'checkout'
      self.save!
    elsif self.paypal_capture_id.nil? && (order_status=='Pending'&&order_reason!='authorization') then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'checkout'
      self.save!
    elsif self.paypal_capture_id.nil? && ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(order_status) then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'cancelled'
      self.save!
    elsif self.paypal_capture_id.nil? && order_status=='Pending' && order_reason=='authorization' then
      self.paypal_attention = false
      self.paypal_issue = nil
      self.status = 'paid'
      self.save!
    elsif ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(order_status) && ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(capture_status) then
      self.paypal_attention = false
      self.paypal_issue = nil
      self.status = 'confirmed'
      self.save!
    elsif order_status=='Pending' && order_reason=='authorization' && ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(capture_status) then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'confirmed'
      self.save!
    elsif ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(capture_status) then
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.save!
    elsif ['Completed', 'Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal'].include?(order_status) && ['Reversed', 'Denied', 'Failed', 'Refunded'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.paypal_attention = false
      self.paypal_issue = nil
      self.status = 'cancelled'
      self.save!
    elsif order_status=='Pending' && order_reason=='authorization' && ['Reversed', 'Denied', 'Failed', 'Refunded'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid' unless self.status == 'cancelled'
      self.save!
    elsif ( ['Expired', 'Voided', 'Reversed', 'Denied', 'Failed', 'Refunded', 'Processed'].include?(order_status) || (order_status=='Pending' && order_reason!='authorization')) && ['Reversed', 'Denied', 'Failed', 'Refunded'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'cancelled'
      self.save!
    elsif order_status=='Pending' && order_reason=='authorization' && ['Processed', 'Pending'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid'
      self.save!
    elsif ['Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal', 'Completed', 'Processed'].include?(order_status) &&  ['Processed', 'Pending'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid'
      self.save!
    elsif order_status=='Pending' && order_reason!='authorization' && (capture_status == 'Processed' || (capture_status=='Pending' && capture_reason!='authorization')) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid'
      self.save!
    elsif order_status=='Pending' && order_reason=='authorization' && ['Expired', 'Voided'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid' unless self.status == 'cancelled'
      self.save!
    elsif ['Pending', 'Processed'].include?(order_status) && ['Expired', 'Voided'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid' unless self.status == 'cancelled'
      self.save!
    elsif ['Expired', 'Voided', 'Reversed', 'Denied', 'Failed', 'Refunded', ].include?(order_status) && ['Expired', 'Voided'].include?(capture_status) then
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'paid' unless self.status == 'cancelled'
      self.save!
    elsif ['Completed-Funds-Held', 'Partially-Refunded', 'Canceled-Reversal', 'Completed', 'Expired', 'Voided', 'Reversed', 'Denied', 'Failed', 'Refunded'].include?()
      ##TODO raise warning if confirmed/delivered
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.status = 'cancelled'
      self.save!
    else
      self.attention!
      self.paypal_issue = "Order=#{order_status} #{order_reason} ; Capture=#{capture_status} #{capture_reason}"
      self.save!
      raise DBTechnicalError.new "Unexpected case !!!!"
    end

  end

  ##
  ## END OF PAYPAL TRANSACTIONS
  ##

end
