require 'money'
require 'eu_central_bank'
require 'shop'

class ShopPagesController < ApplicationController

  #before_filter :init_fbconnection #init the graph connection and everyhting user related
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  #require 'rubygems'
  layout 'main_layout'


  def read

    @pagename = "LOGBOOK"
    @ga_page_category = 'shop'
    @tab = :overview ## by default we want the overview tab

    if params[:vanity_url]!= nil then
      @owner = User.find_by_vanity_url(params[:vanity_url])
    end
    if @owner.nil? || (!@owner.nil? && @owner.shop_proxy_id.nil?) then
      #user doesn't exist
      logger.debug "apparently can't find the shop with url #{params[:vanity_url]} "
      render 'layouts/404', :layout => false
      return
    end

    #Don't display edit page if the user has no rights for that
    if params[:content] == :edit && (!@user || !@user.can_edit?(@owner)) then
      if @user.nil?
        signup_popup_force_private
        params[:content] = :view
      else
        redirect_to @owner.permalink unless params[:partial]
        return
      end
    end

    @fb_appid = FB_APP_ID
    @root_tiny_url = ROOT_TINY_URL
    @gmapskey = GOOGLE_MAPS_API
    @shop = @owner.shop_proxy

    Rails.logger.debug "Shop details: #{@shop.inspect}"

    if params[:content] == :view
      Rails.logger.debug "Using @shop.view_realms"
      @available_menus = @shop.view_realms
    elsif params[:content] == :edit
      Rails.logger.debug "Using @shop.edit_realms"
      @available_menus = @shop.edit_realms
    else
      params[:content] = :view
      @available_menus = @shop.view_realms
    end
    default_realm = @available_menus.first

    #Handling shop claims
    if !params[:valid_claim].blank? && !@owner.shop_proxy.nil? then
      begin
        @valid_claim = ShopClaimHelper.check_claim_user(params[:valid_claim])
        if @valid_claim[:group] != @owner then
          @valid_claim = nil
          raise DBArgumentError.new 'Malformed url: claim does not match shop'
        end
        #Wild card claim links
        if @valid_claim[:user].nil? && @user.nil? then
          ## the login popup will show
          @valid_claim = nil
          params[:valid_claim] = nil
          signup_popup_force_private ## we want to force popup if user not logged
          #redirect_to '/login/register'
          #return
        elsif @valid_claim[:user].nil? && !@user.nil? then
          @valid_claim[:user] = @user
        end
        default_realm = 'profile'
        Rails.logger.debug "Displaying claim validation form"
      rescue DBException => e
        Rails.logger.debug "Claim not valid : #{e.message}"
        redirect_to @owner.permalink, :flash =>{:notice => e.message}
        return
      end
    end

    if !params[:realm].blank? && @available_menus.include?(params[:realm]) then
      default_realm = params[:realm]
    end

    @rendered_realms = []
    shop_widgets = @shop.widgets
    @available_menus.each do |realm|
      Rails.logger.debug "Parsing realm #{realm}"
      fixed_partial_name =  "shop_#{realm.underscore}_#{params[:content]}"
      has_fixed_partial = File.exists?(Rails.root.join("app", "views", params[:controller], "_#{fixed_partial_name}.html.erb"))
      fixed_partial_name = nil if !has_fixed_partial

      has_widget_page = Shop::REALMS_WITH_WIDGETS.include?(realm)

      initial_tab = :fixed
      initial_tab = :widgets unless has_fixed_partial

      @rendered_realms.push({
        :name => realm,
        :display_tabs => (has_fixed_partial && has_widget_page),
        :tabbed => (realm == 'marketing'),
        :fixed => fixed_partial_name,
        :widgets => has_widget_page && (shop_widgets[realm] || []),
        :initial_tab => initial_tab,
        :initial_realm => (realm == default_realm)
      })
    end


    if params[:basket_id] then
      logger.debug "trying to find basket #{params[:basket_id]}"
      @basket = Basket.decode_reference(params[:basket_id]) rescue Basket.fromshake(params[:basket_id])
      logger.debug "Basket: #{@basket.inspect}"
      @basket = nil unless @basket.shop == @shop
    else
      @basket = nil
    end

    if params[:message_id] then
      logger.debug "trying to find message #{params[:message_id]}"
      @message = InternalMessage.fromshake(params[:message_id])
      logger.debug "Message: #{@message.inspect}"
      @message = nil unless @message.to_id == @shop.user_proxy.id || @message.from_id == @shop.user_proxy.id || @message.from_group_id == @shop.user_proxy.id

      if @message.in_reply_to.is_a? Basket then
        @basket ||= @message.in_reply_to
      end

    else
      @message = nil
    end

    if params[:customer_id] then
      logger.debug "trying to find message #{params[:customer_id]}"
      @customer = User.fromshake(params[:customer_id])
      logger.debug "Customer: #{@customer.inspect}"
    elsif !@customer
      @customer = nil
    end

    if params[:partial] then
      partial_realm = @rendered_realms.reject do |realm| realm[:name] != params[:partial] end .first
      if partial_realm && partial_realm[:fixed] then
        render :layout => false, :partial => partial_realm[:fixed], :locals => {:shop => @shop}
        return
      elsif partial_realm && partial_realm[:widgets] then
        render :partial => 'widget_page', :locals => { :widgets => partial_realm[:widgets], :realm_name => partial_realm[:name], :shop => @shop }
      end
    end

    logger.debug "@rendered_realms is : #{@rendered_realms.inspect}"
    logger.debug "Message: #{@message.inspect}"

    return
  end

  def post_claim_uservoice
    begin
      raise DBArgumentError.new 'You must be authenticated' if @user.nil?
      group = User.find(params[:group_id]) rescue nil
      raise DBArgumentError.new "Group does not exist", group_id: params[:group_id] if group.nil?
      raise DBArgumentError.new "You are already admin of that shop" if Membership.where({:user_id => @user.id, :group_id => params[:group_id], :role => 'admin'}).count > 0
      raise DBArgumentError.new 'Some explanation must be provided' if params[:explanation].blank?

      #preventing post on uservoice for stage environment
      if Rails.env == 'staging'
        render :json => {success: true}
        return
      end

      validation_url = ShopClaimHelper.generate_url_confirm_claim(@user, group)

      uri = URI.parse(URI.escape("https://diveboard.uservoice.com/api/v1/tickets.json?client=Iz7G0anniBFGg53Yycpug"))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({
        "email" => "shops@diveboard.com",
        "name" => "Shop Claims",
        "ticket[subject]" => "Shop claim: #{group.shop_proxy.name} (#{group.id})",
        "ticket[message]" => "User: #{@user.nickname}(#{@user.id}) - #{@user.fullpermalink(:canonical)} - #{@user.contact_email}\n\n"+
                             "Shop: #{group.shop_proxy.name} (#{group.shop_proxy_id}) - #{group.shop_proxy.web} - #{group.shop_proxy.email}\n\n"+
                             "User said:\n--------------------------\n#{params[:explanation]}\n--------------------------\n\n\n"+
                             "Click on this link to validate ownership:\n#{validation_url}"
        })

      response = http.request(request)
      logger.debug "Uservoice response : #{response.code} #{response.body}"

      raise DBTechnicalError.new "Technical error while storing the request. Please try again later" if response.code != '200'

      ticket = JSON.parse(response.body) rescue {}
      logger.debug "Uservoice Ticket id: #{ticket['ticket']['id']}" rescue raise DBTechnicalError.new "Error in Uservoice response"

      render :json => {success: true}
    rescue
      render :json => api_exception($!, $!.message)
    end
  end

  def mail_claim_shop
    begin
      raise DBArgumentError.new 'You must be authenticated' if @user.nil?
      group = User.find(params[:group_id]) rescue nil
      raise DBArgumentError.new "Group does not exist", group_id: params[:group_id] if group.nil?
      raise DBArgumentError.new "User is not a group", group_id: params[:group_id] if !group.is_group?
      return if Membership.where({:user_id => @user.id, :group_id => params[:group_id], :role => 'admin'}).count > 0

      NotifyShop.notify_claim(group.shop_proxy, @user, session[:utm_campaign]).deliver

      render :json => {success: true}
    rescue
      render :json => api_exception($!, $!.message)
    end
  end

  def confirm_claim_user
    begin
      args = ShopClaimHelper.check_claim_user(params[:c])

      if args[:user].nil? then
        if @user then
          args[:user] = @user
        else
          render :json => {success: false}
          return
        end
      end

      if Membership.where({:user_id => args[:user].id, :group_id => args[:group].id, :role => 'admin'}).count == 0 then
        Membership.create :user_id => args[:user].id, :group_id => args[:group].id, :role => 'admin'
        Notification.create :kind => 'shop_granted_rights', :user_id => args[:user].id, :about => args[:group].shop_proxy
      end

      if args[:group].source.nil? && !args[:source].blank? then
        args[:group].update_attribute :source, args[:source]
      end

      render :json => {success: true}
    rescue
      render :json => api_exception($!, $!.message)
    end
  end

  def report_review
    begin
      #TODO: enforce login
      review = Review.find(params[:id])
      review.reported_spam = true
      review.save!
      render :json => {success: true}
    rescue
      render :json => api_exception($!, $!.message)
    end
  end

  def test_new_shop 
    @shop = Shop.find(4288)
    render layout: 'responsive_layout'
  end

  def command
    begin
      logger.debug "in"
      logger.debug params[:shop_id]

      @shop = Shop.find(params[:shop_id])

      @recipient = @shop
      @buyer = User.find(params[:user_id])
      @basket= Basket.find(params[:basket_id])
      #NotifyShop.notify_request(params[:shop_id], params[:user_id], params[:basket_id],params[:message], params[:subject])
      NotifyShop.notify_command(@shop,@user,@basket,params[:message], params[:subject]).deliver
      render :json => {success: true}
    rescue
      render :json => api_exception($!, $!.message)
    end
  end

end
