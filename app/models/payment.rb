require 'private_attrs'
class Payment < ActiveRecord::Base
  belongs_to :user
  before_create :default_vals

  belongs_to :subscription_plan

  private_setters :cancellation_date, :refund_date, :confirmation_date  #, :status cf line 220

  # Status chain :
  #    pending -> confirmed, cancelled
  #    confirmed -> refunded
  #    cancelled, refunded -> N/A

  def default_vals
    logger.debug 'setting default to pending'
    self.status = 'pending'
  end

  def self.for_storage(plan_id, donation, user_id)
    raise DBArgumentError.new "Unknown plan", plan_id: plan_id if Rails.application.config.storage_plans[plan_id].nil?

    available_plans = User.find(user_id).available_storage_plans
    raise DBArgumentError.new "Unauthorized plan", plan_id: plan_id, user_id: user_id if available_plans[plan_id].nil?
    raise DBArgumentError.new "Asking to pay a negative amount" if available_plans[plan_id][:price] < 0

    new_payment = Payment.create do |p|
      p.category = 'storage'
      p.user_id = user_id
      p.validity_date = Time.now
      p.amount =  available_plans[plan_id][:price]
      p.donation = donation
      p.storage_duration = available_plans[plan_id][:duration]
      p.storage_limit = available_plans[plan_id][:quota]
    end

    begin
      request = {
        :actionType => 'PAY',
        :returnUrl => "#{ROOT_URL.chop}/api/paypal/return?c=success&t=plan&p=#{new_payment.id}",
        :cancelUrl => "#{ROOT_URL.chop}/api/paypal/return?c=cancel&t=plan&p=#{new_payment.id}",
        :requestEnvelope => { :errorLanguage => "en_US"},
        :currencyCode => "USD",
        :receiverList => {
          :receiver => [{
            :email => Rails.application.config.paypal[:receiver_email],
            :paymentType => 'DIGITALGOODS',
            :amount => (new_payment.amount + donation.to_i)
          }]
        }
      }

      header = {
        'X-PAYPAL-SECURITY-USERID' => Rails.application.config.paypal[:api_username],
        'X-PAYPAL-SECURITY-PASSWORD' => Rails.application.config.paypal[:api_password],
        'X-PAYPAL-SECURITY-SIGNATURE' => Rails.application.config.paypal[:api_signature],
        'X-PAYPAL-APPLICATION-ID' => Rails.application.config.paypal[:app_id],
        'X-PAYPAL-REQUEST-DATA-FORMAT' => 'JSON',
        'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON'
      }

      logger.debug header
      logger.debug request

      uri = URI.parse(URI.escape('https://'+Rails.application.config.paypal[:api_host]+'/AdaptivePayments/Pay'))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri.path, request.to_json, header)
      logger.debug response.body

      data = JSON.parse(response.body)

      if data['paymentExecStatus'] != 'CREATED' || data['responseEnvelope']['ack'] != 'Success' then
        raise DBArgumentError.new 'Call to Paypal was not successful'
      end

      new_payment.ref_paypal = data['payKey']
      new_payment.save!

    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      new_payment.cancel!
      return nil
    end

    return new_payment
  end

  def check_status!
    if recurring
      return check_subscription_status!
    else
      return check_oneshot_status!
    end
  end


  def confirm!
    return self if confirmed?
    raise DBArgumentError.new 'Payment is not expecting confirmation' if !['pending', 'suspended'].include?(status)
    logger.info "Confirmation of payment #{self.id} - #{self.ref_paypal}"
    self.status = 'confirmed'
    confirmation_date = Time.now
    save!
    self.user.update_quota! if self.category == 'storage'
  end

  def confirmed?
    return (self.status == 'confirmed')
  end

  def cancel!
    return self if cancelled?
    raise DBArgumentError.new 'Payment is not expecting cancellation' if !self.recurring && self.status != 'pending'
    raise DBArgumentError.new 'Payment is not expecting cancellation' if self.recurring && !['pending', 'suspended', 'confirmed'].include?(self.status)
    logger.info "Cancellation of payment #{self.id} - #{self.ref_paypal}"
    self.status = 'cancelled'
    cancellation_date = Time.now
    save!
    self.user.update_quota! if self.category == 'storage'
  end

  def cancelled?
    return self.status == 'cancelled'
  end

  def suspended?
    return self.status == 'suspended'
  end

  def suspend!
    return self if suspended?
    raise DBArgumentError.new 'Payment is not expecting suspension' if !self.recurring
    raise DBArgumentError.new 'Payment is not expecting suspension' if !['confirmed', 'pending'].include?(self.status)
    logger.info "Suspension of payment #{self.id} - #{self.ref_paypal} - #{self.rec_profile_paypal}"
    self.status = 'suspended'
    save!
    self.user.update_quota! if self.category == 'storage'
  end

  def refund!
    return self if refunded?
    raise DBArgumentError.new 'Payment is not expecting refund' if self.recurring
    raise DBArgumentError.new 'Payment is not expecting refund' if self.status != 'confirmed'
    logger.info "Refund of payment #{self.id} - #{self.ref_paypal}"
    self.status = 'refunded'
    refund_date = Time.now
    save!
    self.user.update_quota! if self.category == 'storage'
  end

  def refunded?
    return self.status == 'refunded'
  end

  def ref_paypal=(val)
    raise DBArgumentError.new 'ref_paypal cannot be modified once it is set' unless ref_paypal.nil?
    write_attribute(:ref_paypal, val)
  end

  def rec_profile_paypal=(val)
    raise DBArgumentError.new 'rec_profile_paypal cannot be modified once it is set' unless rec_profile_paypal.nil?
    write_attribute(:rec_profile_paypal, val)
  end

  def user_id=(val)
    raise DBArgumentError.new 'user_id cannot be modified once it is set' unless user_id.nil?
    write_attribute(:user_id, val)
  end




  def self.for_plan_pro(subscription_plan_id, user_id, shop_id)
    plan = SubscriptionPlan.find(subscription_plan_id)
    raise DBArgumentError.new "Unknown plan", plan_id: subscription_plan_id if plan.nil?
    raise DBArgumentError.new "Unauthorized plan", plan_id: subscription_plan_id, user_id: user_id if !plan.available

    price = plan.price
    raise DBArgumentError.new "Asking to pay a negative amount" if price < 0

    label = "Diveboard - #{plan.title}"
    label += " #{plan.option_title}" if !plan.option_title.blank?

    new_payment = Payment.create do |p|
      p.category = 'plan_pro'
      p.subscription_plan_id = subscription_plan_id
      p.recurring = 'true'
      p.user_id = user_id
      p.validity_date = Time.now
      p.amount =  price
      p.shop_id = shop_id
    end

    begin
      request = Paypal::Express::Request.new(
        :username   => Rails.application.config.paypal[:api_username],
        :password   => Rails.application.config.paypal[:api_password],
        :signature  => Rails.application.config.paypal[:api_signature]
      )

      payment_request = Paypal::Payment::Request.new(
        :currency_code => :USD,
        :billing_type  => :RecurringPayments,
        :billing_agreement_description => label
      )

      response = request.setup(
        payment_request,
        "#{ROOT_URL.chop}/api/paypal/subscription_return?c=success&t=plan_pro&p=#{new_payment.id}",
        "#{ROOT_URL.chop}/api/paypal/subscription_return?c=cancel&t=plan_pro&p=#{new_payment.id}",
        :no_shipping => true
      )

      new_payment.ref_paypal = response.token
      new_payment.save!

      return response.popup_uri
    rescue
      new_payment.status = 'cancelled'
      new_payment.save
      raise $!
    end

    return nil
  end


  def transform_into_subscription!
    raise DBArgumentError.new "Unknown plan", plan_id: self.subscription_plan_id if self.subscription_plan.nil?
    raise DBArgumentError.new "Unauthorized plan", plan_id: self.subscription_plan_id, user_id:user_id if !self.subscription_plan.available
    raise DBArgumentError.new "Asking to pay a negative amount" if subscription_plan.price < 0

    label = "Diveboard - #{subscription_plan.title}"
    label += " #{subscription_plan.option_title}" if !subscription_plan.option_title.blank?

    request = Paypal::Express::Request.new(
      :username   => Rails.application.config.paypal[:api_username],
      :password   => Rails.application.config.paypal[:api_password],
      :signature  => Rails.application.config.paypal[:api_signature]
    )

    profile = Paypal::Payment::Recurring.new(
      :start_date => self.validity_date.strftime("%Y-%m-%dT00:00:00Z"),
      :description => label,
      :billing => {
        :period        => :Month, # ie.) :Month, :Week
        :frequency     => self.subscription_plan.period,
        :amount        => subscription_plan.price,
        :currency_code => :USD # if nil, PayPal use USD as default
      }
    )

    response = request.subscribe!(self.ref_paypal, profile)

    self.rec_profile_paypal = response.recurring.identifier
    self.save!
    self.confirm!

    Payment.where("id <> #{self.id}").where(:status => ['confirmed','pending','suspended'], :category => 'plan_pro', :shop_id => self.id).each do |p|
      p.stop_subscription!
    end
  end

  def stop_subscription!
    return if !recurring
    return unless ['pending', 'confirmed', 'suspended'].include?(self.status)

    if self.rec_profile_paypal.nil? then
      self.cancel!
      return
    end

    begin
      request = Paypal::Express::Request.new(
        :username   => Rails.application.config.paypal[:api_username],
        :password   => Rails.application.config.paypal[:api_password],
        :signature  => Rails.application.config.paypal[:api_signature]
      )

      request.renew!(self.rec_profile_paypal, :Cancel)
      self.cancel!
    rescue
      Rails.logger.error $!.message
      Rails.logger.debug $!.backtrace.join "\n"
      ExceptionNotifier::Notifier.background_exception_notification($!).deliver
      raise $!
    end
  end













private
  def delete
    super
  end

  def destroy
    super
  end

  def check_oneshot_status!
    begin
      request = {
        :requestEnvelope => { :errorLanguage => "en_US"},
        :payKey => self.ref_paypal
      }

      header = {
        'X-PAYPAL-SECURITY-USERID' => Rails.application.config.paypal[:api_username],
        'X-PAYPAL-SECURITY-PASSWORD' => Rails.application.config.paypal[:api_password],
        'X-PAYPAL-SECURITY-SIGNATURE' => Rails.application.config.paypal[:api_signature],
        'X-PAYPAL-APPLICATION-ID' => Rails.application.config.paypal[:app_id],
        'X-PAYPAL-REQUEST-DATA-FORMAT' => 'JSON',
        'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON'
      }

      logger.debug header
      logger.debug request

      uri = URI.parse(URI.escape('https://'+Rails.application.config.paypal[:api_host]+'/AdaptivePayments/PaymentDetails'))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri.path, ActiveSupport::JSON.encode(request), header)
      logger.debug "Paypal response : #{response.body}"

      data = ActiveSupport::JSON.decode(response.body)

      if data['responseEnvelope']['ack'] != 'Success' then
        raise DBTechnicalError.new 'Call to Paypal was not successful'
      end

      # Other status include : CREATED, INCOMPLETE, PROCESSING, PENDING; REVERSALERROR should probably never happen
      if data['status'] == 'ERROR' then
        cancel!
      elsif ['pending', 'suspended'].include?(status) && data['status'] == 'COMPLETED' then
        confirm!
      end

      if data['paymentInfoList'] && data['paymentInfoList']['paymentInfo'] && data['paymentInfoList']['paymentInfo'].first && data['paymentInfoList']['paymentInfo'].first['transactionStatus'] == 'REFUNDED' then
        refund!
      end

      if status == 'pending' && self.created_at > Time.now + Rails.application.config.paypal[:delay_pending_before_cancel] then
        cancel!
      end

      self
    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      raise
    end
  end


  def check_subscription_status!

    request = Paypal::Express::Request.new(
      :username   => Rails.application.config.paypal[:api_username],
      :password   => Rails.application.config.paypal[:api_password],
      :signature  => Rails.application.config.paypal[:api_signature]
    )
    begin
      if ref_paypal && !rec_profile_paypal then
        response = request.details(self.ref_paypal) rescue nil
        if response.nil?
          cancel!
        elsif response.billing_agreement_accepted_status.to_i == 1 then
          transform_into_subscription!
        end
        #else transaction is pending for an answer

      else
        response = request.subscription(self.rec_profile_paypal)

        confirm! if response.recurring.status == 'Active' #Other values Pending, Cancelled, Suspended, Expired
        cancel! if response.recurring.status == 'Cancelled' #Other values Pending, Cancelled, Suspended, Expired
        cancel! if response.recurring.status == 'Expired' #Other values Pending, Cancelled, Suspended, Expired
        suspend! if response.recurring.status == 'Suspended' #Other values Pending, Cancelled, Suspended, Expired
        #r.recurring.summary.outstanding_balance < 0.01 # amount not paid
        #r.recurring.summary.failed_count #should be 0
        #r.recurring.summary.last_payment_date #should be less than 1 month ago
      end

    rescue
      Rails.logger.error $!.message
      Rails.logger.debug $!.backtrace.join "\n"
      ExceptionNotifier::Notifier.background_exception_notification($!).deliver
      raise $!
    end

  end


end
