class PaymentsController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache

  def success
    logger.debug params
  end

  def start
    begin

      if !@user.can_subscribe params[:item].to_sym then
        render :layout => false, :json => {:success => false, :error => 'You cannot subscribe to this plan' }
        return
      end

      new_payment = Payment.for_storage(params[:item].to_sym, params[:donation], @user.id)
      render :layout => false, :json => {:success => true, :url => Rails.application.config.paypal[:url]+'?paykey='+new_payment.ref_paypal, :key => new_payment.ref_paypal, :id => new_payment.id }

    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      render :layout => false, :json => {:success => false, :error => "call to paypal failed" }
    end
  end

  def return
    pay=nil
    begin
      raise DBArgumentError.new 'Missing parameter c' if params[:c].nil?
      raise DBArgumentError.new 'Missing parameter p' if params[:p].nil?
      raise DBArgumentError.new 'Missing parameter t' if params[:t].nil?

      if params[:t] == 'plan' then
        pay = Payment.find(params[:p].to_i)
      else
        pay = BasketPayment.find(params[:p].to_i)
      end
      raise DBArgumentError.new 'Unknown payment' if pay.nil?

      pay.check_status!
      pay.cancel! if params[:c] == 'cancel' && pay.status == 'pending'
      logger.warn 'Paypal returned but has not yet processed the request' if params[:c] == 'success' && pay.status == 'pending'

      @alert_cancelled = true if pay.cancelled?

      render :layout => false, :locals => {:alert_cancelled => pay.cancelled?, :reload => params[:c] == 'success'}

    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      @alert_failed = true if pay.cancelled?
    end
  end

  def permission_start
    begin
      raise DBArgumentError.new 'You must be authentified' if @user.nil?
      raise DBArgumentError.new 'Missing parameter shop_id' if params[:shop_id].nil?

      shop = Shop.fromshake(params[:shop_id])

      raise DBArgumentError.new "You don't have the permission to do that" unless shop.is_private_for?({:caller => @user})

      if !params[:paypal_id].blank? then
        shop.paypal_id = params[:paypal_id]
        shop.save!
      end
      redirect_to shop.paypal_gen_permission_request_url

    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      @alert_failed = true
      render :text => $!.message
    end
  end

  def permission_return
    begin
      raise DBArgumentError.new 'Missing parameter i' if params[:i].nil?
      raise DBArgumentError.new 'Missing parameter s' if params[:s].nil?
      raise DBArgumentError.new 'Missing parameter r' if params[:r].nil?

      if (!params[:request_token].blank? && !params[:verification_code].blank?) then
        shop = Shop.fromshake(params[:i])
        shop.paypal_validate_id params[:s], params[:request_token], params[:verification_code]
      end

      redirect_to params[:r]
    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      @alert_failed = true
      render :text => $!.message
    end
  end

  def subscription_return
    begin
      raise DBArgumentError.new 'Missing parameter c' if params[:c].nil?
      raise DBArgumentError.new 'Missing parameter token' if params[:token].nil?

      payment = Payment.where(:ref_paypal => params[:token]).first

      if params[:c] == "success" then
        if payment.recurring then
          payment.transform_into_subscription!
          session[:pro_register_payment] = payment.id
        else
          payment.check_status!
        end
      end

      render 'return', :layout => false, :locals => {:alert_cancelled => payment.cancelled?, :reload => params[:c] == 'success'}

    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      flash[:notif] = "Error while coming back from Paypal."
      render :text => "ERROR: #{$!.message}"
    end
  end

  def basket_return
    begin
      raise DBArgumentError.new 'Missing parameter c' if params[:c].nil?
      raise DBArgumentError.new 'Missing parameter token' if params[:token].nil?

      if params[:c] == "success" then
        baskets = Basket.receive_payment params[:token]
        redirect_to '/pro/payment_success/' + baskets.first.shaken_id
      else
        if @user
          redirect_to @user.fullpermalink(:locale)
        else
          redirect_to '/'
        end
      end
    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      @alert_failed = true
      render :text => "ERROR: #{$!.message}"
    end
  end

  def basket_ipn
    render :text => ''

    paypal_message = request.raw_post

    #Verifying the validity of the IPN with Paypal
    uri = URI.parse(URI.escape(Rails.application.config.paypal[:api_3t_url]))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.post(uri.path, "cmd=_notify-validate&#{paypal_message}")

    logger.debug "IPN verification: #{response.body}"
    if response.body != "VERIFIED" then
      Rails.logger.error "IPN received has been rejected while validating"
      return
    end

    #Trying to find related basket
    #For orders: txn_id = order_id, no parent_txn_id, "transaction_entity"=>"order"
    #For payments: txn_id = capture_id, parent_txn_id = order_id, "transaction_entity"=>"payment"
    #For refunds: txn_id = refund_id, parent_txn_id = capture_id, "transaction_entity"=>"payment"
    basket = Basket.where(:paypal_capture_id => params[:txn_id]).first unless params[:txn_id].nil?
    basket ||= Basket.where(:paypal_order_id => params[:txn_id]).first unless params[:txn_id].nil?
    basket ||= Basket.where(:paypal_capture_id => params[:parent_txn_id]).first unless params[:parent_txn_id].nil?
    basket ||= Basket.where(:paypal_order_id => params[:parent_txn_id]).first unless params[:parent_txn_id].nil?

    if basket.nil? then
      Rails.logger.error "IPN received for Unknown basket !!!"
      return
    end

    if basket.paypal_order_id == params[:parent_txn_id] && basket.paypal_capture_id.nil? then
      Rails.logger.debug "IPN update of paypal_capture_id #{params[:txn_id]} on basket #{basket.id} for paypal_order_id #{params[:parent_txn_id]}"
      basket.paypal_capture_id = params[:txn_id]
      basket.paypal_capture_date = Time.now
      basket.save
    elsif basket.paypal_capture_id == params[:parent_txn_id] && basket.paypal_refund_id.nil? && params[:payment_status] == 'Refunded' then
      Rails.logger.debug "IPN update of paypal_refund_id #{params[:txn_id]} on basket #{basket.id} for paypal_capture_id #{params[:parent_txn_id]}"
      basket.paypal_refund_id = params[:txn_id]
      basket.paypal_refund_date = Time.now
      basket.save
    end

    begin
      basket.check_status! unless basket.nil?
    rescue
      NotificationHelper.mail_background_exception $!
      Rails.logger.error $!.message
      Rails.logger.debug $!.backtrace.join "\n"
    end

  end

end
