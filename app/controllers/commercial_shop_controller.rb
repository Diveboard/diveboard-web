class CommercialShopController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :signup_popup_hidden
  before_filter :init_register_state, :init_register_steps
  respond_to :html, :json # means that by default we reply with html
  layout 'main_layout'


  def index
    @pagename = "PRO"
    @ga_page_category = "home_pro"
  end

  def init_register_state
    if params[:start] then
      session[:pro_register_payment] = nil
      session[:pro_register_plan_id] = nil
      session[:pro_register_optn_id] = nil
      session[:pro_register_shop_id] = nil
      session[:pro_register_shop_js] = nil
      session[:pro_register_payment] = nil
      session[:pro_register_unsubsc] = nil
      session[:pro_register_claim  ] = nil
    end

    @payment = params[:pay]
    @payment ||= session[:pro_register_payment]
    session[:pro_register_payment] = @payment

    if params[:new_shop] then
      @tmp_shop_valid = validate_shop_json params[:new_shop]
      @tmp_shop = @tmp_shop_valid[:filtered_hash]
      session[:pro_register_shop_js] = params[:new_shop]
      if !@tmp_shop_valid[:ok]
        flash[:notice] = @tmp_shop_valid[:errors].map do |e| e[:error_message] end
      end
    elsif session[:pro_register_shop_js] then
      @tmp_shop_valid = validate_shop_json session[:pro_register_shop_js]
      @tmp_shop = @tmp_shop_valid[:filtered_hash]
    end
    @new_shop = Shop.new(@tmp_shop_valid[:shop_hash]) if @tmp_shop_valid && @tmp_shop_valid[:ok]
    session[:pro_register_shop_id] = nil if @new_shop

    session[:pro_register_claim] = nil if params[:shop_id]
    @shop = Shop.find(params[:shop_id]) rescue nil
    @shop ||= Shop.find(session[:pro_register_shop_id]) rescue nil
    if @shop && @user && !@shop.is_private_for?(caller: @user) && @shop.is_claimed? then
      @shop = nil
      flash[:notice] = "This shop is already registered by someone else."
    end
    session[:pro_register_shop_id] = @shop.id unless @shop.nil?
    session[:pro_register_shop_js] = nil unless @shop.nil?


    @plan_id = params[:plan]
    @plan_id ||= session[:pro_register_plan_id]
    #in case someone tries to subscribe the same plan he already has
    @plan_id = nil if @plan_id != 'free' && @shop && @shop.subscribed_plan.name == @plan_id && !@payment
    @options = SubscriptionPlan.where(:category => 'plan_pro', :name => @plan_id, :available => true)
    @plan_id = @options.first.name rescue nil
    session[:pro_register_plan_id] = @plan_id


    @option_id = params[:option_id]
    @option_id ||= session[:pro_register_optn_id]
    @option_id ||= @options.first.option_name if @options.count == 1
    @option = @options.where(:option_name => @option_id).first rescue nil
    @option_id = @option.option_name rescue nil
    session[:pro_register_optn_id] = @option_id

    #reset ubsubscription confirmation if anything changes
    if !params.slice(:plan, :shop_id, :new_shop).map(&:blank?).all? then
      session[:pro_register_unsubsc] = nil
    end

    @confirm_unsubscribe = params[:unsubscribe]
    @confirm_unsubscribe ||= session[:pro_register_unsubsc]
    session[:pro_register_unsubsc] = @confirm_unsubscribe

    @shop_claim_detail = params[:claim]
    @shop_claim_detail ||= session[:pro_register_claim]
    session[:pro_register_claim] = @shop_claim_detail

    Rails.logger.debug "Pro register session: pro_register_payment: #{session[:pro_register_payment].inspect}"
    Rails.logger.debug "Pro register session: pro_register_plan_id: #{session[:pro_register_plan_id].inspect}"
    Rails.logger.debug "Pro register session: pro_register_optn_id: #{session[:pro_register_optn_id].inspect}"
    Rails.logger.debug "Pro register session: pro_register_shop_id: #{session[:pro_register_shop_id].inspect}"
    Rails.logger.debug "Pro register session: pro_register_shop_js: #{session[:pro_register_shop_js].inspect}"
    Rails.logger.debug "Pro register session: pro_register_payment: #{session[:pro_register_payment].inspect}"
    Rails.logger.debug "Pro register session: pro_register_unsubsc: #{session[:pro_register_unsubsc].inspect}"
    Rails.logger.debug "Pro register session: pro_register_claim  : #{session[:pro_register_claim  ].inspect}"

  end

  #Step alchemy
  def init_register_steps
    if @user.nil?
      @allowed_steps = [:user, :business, :plan]
      @next_step = :user
      signup_popup_force
    elsif @shop.nil? && @new_shop.nil?
      @allowed_steps = [:business, :plan]
      @next_step = :business
    elsif @shop && !@shop.is_private_for?(caller: @user) && @shop_claim_detail.nil? then
      @allowed_steps = [:business, :plan, :make_shop_claim]
      @next_step = :make_shop_claim
    elsif @plan_id.nil?
      @allowed_steps = [:business, :plan]
      @next_step = :plan
    elsif @shop && @shop.subscribed_plan(false).name != 'free' && !@confirm_unsubscribe && !@payment
      @allowed_steps = [:business, :plan, :confirm_unsubscribe]
      @next_step = :confirm_unsubscribe
    elsif @options.count == 1 && @option.price.nil?
      @allowed_steps = [:business, :plan, :confirm_claim, :confirm_claim_ex, :confirm_claim_mail, :redirect_shop, :redirect_shop_with_unsubscribe]
      if @shop && !@shop.is_private_for?(caller: @user)
        @next_step = :confirm_claim
      elsif @shop && @shop.subscribed_plan(false).name != 'free' && @confirm_unsubscribe
        @next_step = :redirect_shop_with_unsubscribe
      else
        @next_step = :redirect_shop
      end
    elsif !@payment && @options.count > 1 && @option_id.nil?
      @allowed_steps = [:business, :plan, :payment_option]
      @next_step = :payment_option
    elsif !@payment && @options.count > 1
      @allowed_steps = [:business, :plan, :payment_option, :checkout]
      @next_step = :payment_option
    elsif !@payment
      @allowed_steps = [:business, :plan, :payment, :checkout]
      @next_step = :payment
    else
      @allowed_steps = [:confirm_claim, :confirm_claim_ex, :confirm_claim_mail, :redirect_shop]
      if @shop && !@shop.is_private_for?(caller: @user)
        @next_step = :confirm_claim
      else
        @next_step = :redirect_shop #todo: confirm pay
      end
    end

    Rails.logger.debug "Next step: #{@next_step}"
    Rails.logger.debug "Allowed steps: #{@allowed_steps.inspect}"
  end

  def register_shop
    @pagename = "PRO"
    @ga_page_category = "register_pro"

    requested_step = params[:step].to_sym rescue nil
    @claimed_shop = Shop.find(params[:claimed]) rescue nil

    if [:confirm_claim, :confirm_claim_ex, :confirm_claim_mail].include?(requested_step) && @claimed_shop then
      @step = requested_step
    elsif !@allowed_steps.include?(requested_step) then
      redirect_next_step
    elsif requested_step == :checkout
      create_new_shop!
      paypal_subscription_start
    else
      @step = requested_step
    end
  end

  def redirect_next_step
    unsubscribe! if @next_step == :redirect_shop_with_unsubscribe

    if @next_step == :redirect_shop || @next_step == :redirect_shop_with_unsubscribe then
      create_new_shop!
      session[:pro_register_payment] = nil
      session[:pro_register_plan_id] = nil
      session[:pro_register_optn_id] = nil
      session[:pro_register_shop_id] = nil
      session[:pro_register_shop_js] = nil
      session[:pro_register_payment] = nil
      session[:pro_register_unsubsc] = nil
      session[:pro_register_claim  ] = nil
      redirect_to "#{@shop.permalink}/edit/welcome"
    elsif [:confirm_claim,:confirm_claim_mail,:confirm_claim_ex].include? @next_step then
      if @shop_claim_detail['method'] == 'mail' then
        NotifyShop.notify_claim(@shop, @user, session[:utm_campaign]).deliver
        redirect_to "/login/register_pro/confirm_claim_mail?claimed=#{@shop.id}"
      elsif @shop_claim_detail['method'] == 'explain' then
        if Rails.env != 'staging' then
          validation_url = ShopClaimHelper.generate_url_confirm_claim(@user, @shop.user_proxy)

          uri = URI.parse(URI.escape("https://diveboard.uservoice.com/api/v1/tickets.json?client=Iz7G0anniBFGg53Yycpug"))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          rq = Net::HTTP::Post.new(uri.request_uri)
          rq.set_form_data({
            "email" => "shops@diveboard.com",
            "name" => "Shop Claims",
            "ticket[subject]" => "Shop claim: #{@shop.name} (#{@shop.id})",
            "ticket[message]" => "User: #{@user.nickname}(#{@user.id}) - #{@user.fullpermalink :canonical} - #{@user.contact_email}\n\n"+
                                 "Shop: #{@shop.name} (#{@shop.id}) - #{@shop.web} - #{@shop.email}\n\n"+
                                 "User said:\n--------------------------\n#{@shop_claim_detail['explanation']}\n--------------------------\n\n\n"+
                                 "Click on this link to validate ownership:\n#{validation_url}"
            })

          rsp = http.request(rq)
          logger.debug "Uservoice response : #{rsp.code} #{rsp.body}"

          raise DBTechnicalError.new "Technical error while storing the request. Please try again later" if rsp.code != '200'

          ticket = JSON.parse(rsp.body) rescue {}
          logger.debug "Uservoice Ticket id: #{ticket['ticket']['id']}" rescue raise DBTechnicalError.new "Error in Uservoice response"
        end

        redirect_to "/login/register_pro/confirm_claim_ex?claimed=#{@shop.id}"
      else
        redirect_to "/login/register_pro"
      end
      session[:pro_register_payment] = nil
      session[:pro_register_plan_id] = nil
      session[:pro_register_optn_id] = nil
      session[:pro_register_shop_id] = nil
      session[:pro_register_shop_js] = nil
      session[:pro_register_payment] = nil
      session[:pro_register_unsubsc] = nil
      session[:pro_register_claim  ] = nil
    else
      redirect_to "/login/register_pro/#{@next_step.to_s}"
    end
  end

  # def test_new_shop 
  #   @shop = Shop.find(4288)
  #   render layout: 'responsive_layout'
  # end

private

  def validate_shop_json shop
    return nil if shop.nil?
    errors = []
    errors.push attribute: 'name', error_message: 'Business name should be at least 4 characters' if shop['name'].nil? || shop['name'].length < 4
    errors.push attribute: 'vanity', error_message: 'URL should be at least 4 characters' if shop['vanity'].nil? || shop['vanity'].length < 4
    errors.push attribute: 'category', error_message: 'Select one of the existing business type' if shop['category'].nil? || !Shop::ALLOWED_CATEGORIES.include?(shop['kind'])
    country = Country.find_by_ccode(shop['country_code']) rescue nil
    errors.push attribute: 'country', error_message: 'Select one of the existing countries' if shop['country_code'].nil? || country.nil?
    errors.push attribute: 'city', error_message: 'City name should be at least 4 characters' if shop['city'].nil? || shop['city'].length < 4

    shop['country_code'] = nil if shop['country_code'].blank?
    shop_h = shop.slice 'name', 'category', 'country_code', 'city'
    h = shop.slice 'name', 'vanity', 'category', 'country_code', 'city'
    h['country_name'] = country.name rescue nil
    return {ok: errors.blank?, errors: errors, filtered_hash: h, shop_hash: shop_h}
  end

  def paypal_subscription_start
    begin
      popup_url = Payment.for_plan_pro @option.id, @user.id, @shop.id
      render :json => {success: true, url: popup_url}
    rescue
      logger.error "Error while calling Paypal : #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      render :json => {success: false, error: $!.message}
    end
  end

  def create_new_shop!
    return unless  @new_shop
    @new_shop.save!
    @new_shop.create_proxy_user!
    @new_shop.reload
    u = @new_shop.user_proxy
    Membership.create :user_id => @user.id, :group_id => u.id, :role => 'admin'
    begin
      u.vanity_url = @tmp_shop['vanity']
      u.save!
    rescue
      Rails.logger.warn $!.message
      ExceptionNotifier::Notifier.exception_notification(request.env, $!).deliver
    end
    @shop = @new_shop
    @new_shop = nil
    session[:pro_register_shop_id] = @shop.id
    session[:pro_register_shop_js] = nil
  end

  def unsubscribe!
    return unless @shop
    @shop.unsubscribe_plan
  end


end
