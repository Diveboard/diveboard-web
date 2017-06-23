require_dependency 'password'
require 'nokogiri'

class ApplicationController < ActionController::Base
  protect_from_forgery
  #use XOriginEnabler, "#{Rails.application.config.explore_balancing_roots.join(" ").gsub("//","")} #{Rails.application.config.ROOT_MOBILE_DOMAIN}"
  helper_method :unit_temp, :unit_distance, :unit_weight
  before_filter :set_locale
  before_filter :log_user_agent, :init_google_analytics, :track_conversion_origin, :signup_popup_hidden
  rescue_from  ActionView::MissingTemplate, :with => :missing_template


  def track_conversion_origin
    if !params[:utm_campaign].nil?  && params[:utm_campaign] != ""
      Rails.logger.debug "User coming from campaign: #{params[:utm_campaign]}"
      session[:utm_campaign] = params[:utm_campaign]
    end
  end

  def set_user user
    ##this is necessary to print pdf ... we need to instantiate app controler and have @user known
    @user=user
  end

  def unit_temp(temperature,addunit,round=0)
    ##by default we render units from the base and all our units are metrics

    if @user.nil?
      unit = "C"
    else
      unit = @user.preferred_units["temperature"]
    end

    Rails.logger.debug round
    Rails.logger.debug temperature

    if temperature.nil? then
      val = nil
    elsif unit == "C" then
      val = temperature.round(round).to_f
    else
      val = (temperature*9/5+32).round(round).to_f
    end

    if round == 0
      val = val.to_i unless val.nil?
    else
      val = val.to_f unless val.nil?
    end

    Rails.logger.debug val

    if val && (round <= 0 || val.round(0).to_i == val) then
      val_string = "%.0f" % val
    elsif val
      val_string = val.to_s
    else
      val_string = ""
    end

    Rails.logger.debug val_string

    if addunit
      return  "#{val_string}&deg;#{unit}".html_safe
    else
      return "#{val_string}".html_safe
    end

  end

  def unit_distance(distance,addunit,round=1)
    ##by default we render units from the base and all our units are metrics

    if @user.nil? || @user.preferred_units["distance"]=="m"
      unit = "m"
    else
      unit = "ft"
    end

    Rails.logger.debug round

    if distance.nil? then
      val = nil
    elsif unit == "m" then
      val = distance.round(round).to_f
    else
      val = (distance*3.2808399).round(round).to_f
    end
    if round == 0
      val = val.to_i unless val.nil?
    else
      val = val.to_f unless val.nil?
    end

    Rails.logger.debug val

    if val && (round <= 0 || val.round(0).to_i == val) then
      val_string = "%.0f" % val
    elsif val
      val_string = val.to_s
    else
      val_string = ""
    end

    Rails.logger.debug val_string

    if addunit
      return  "#{val_string}#{unit}".html_safe
    else
      return "#{val_string}".html_safe
    end
  end

  def unit_weight(weight,addunit,round=1)
    ##by default we render units from the base and all our units are metrics

    if @user.nil? || @user.units["weight"]=="kg"
      unit = "kg"
    else
      unit = "lbs"
    end

    Rails.logger.debug round

    if weight.nil? then
      val = nil
    elsif unit == "kg" then
      val = DBUnit.convert(weight, "kg", "kg")
    else
      val = DBUnit.convert(weight, "kg", "lbs")
    end

    if round == 0
      val = val.to_i unless val.nil?
    else
      val = val.to_f.round(round) unless val.nil?
    end

    Rails.logger.debug val

    if val && (round <= 0 || val.round(0).to_i == val) then
      val_string = "%.0f" % val
    elsif val
      val_string = val.to_s
    else
      val_string = ""
    end

    Rails.logger.debug val_string

    if addunit
      return  "#{val_string}#{unit}".html_safe
    else
      return "#{val_string}".html_safe
    end
  end


  def put_logs
    begin
      init_logged_user
    rescue
    end

    message_title = "Error from browser (javascript) [user: #{@user.vanity_url unless @user.nil?} (#{@user.id unless @user.nil?})] on '#{params[:location]}': #{params[:message]} - #{params[:page]}"
    message = ""

    params.each{|k,t|
      message += "\n\t"
      if k.to_s.length>81920 then
        message += k.to_s[0..81920]+'...'
      else
        message += k.to_s
      end
      message += " :\t"

      if k == 'navigator' || k == 'globals' then
        u={}
        t.each{ |e,v|
          begin
            u[e] = JSON.parse(v)
          rescue
          end
        }
        t=u
      end

      if t.is_a?(Hash) || t.is_a?(Array) then
        t=JSON.pretty_generate(t)
      end

      if t.to_s.length > 81920 then
        message += t.to_s[0..81920].gsub(/\n/,"\n\t\t")+'...'
      else
        message += t.to_s.gsub(/\n/,"\n\t\t")
      end
    }

    case params[:level]
    when /error/i
      logger.error message_title
    when /debug/i
      logger.debug message_title
    when /info/i
      logger.info message_title
    else
      logger.warn message_title
    end
    logger.debug message

    render :json => {:success => true}
  end

  def serve_js_view
    path = params[:dir]
    path.gsub!( /[^a-zA-Z0-9\/_-]/, '')
    js = params[:js]
    js.gsub!( /[^a-z0-9A-Z_.-]/, '')
    render :file => "app/views/#{path}/#{js}.mv.js", :layout => false, :content_type => 'text/javascript'
  end
  def init_inbox
    if @user.nil? then
      Rails.logger.debug "@user is nil"
      @global_inbox = []
      return
    else
      @global_inbox = @user.global_inbox
      return
    end
  end

  def set_locale
    #extracting from subdomain:
    @I18n_requested = extract_locale_from_params || extract_locale_from_subdomain || extract_locale_from_user_prefs || extract_locale_from_accept_language_header
    I18n.locale = extract_locale_from_params || extract_locale_from_subdomain || extract_locale_from_user_prefs || extract_locale_from_accept_language_header || I18n.default_locale
  end

  def extract_locale_from_user_prefs
    begin
      parsed_locale = @user.preferred_locale
      return nil if parsed_locale.nil?
      Rails.logger.debug "User locale: #{parsed_locale} -- #{I18n.available_locales.inspect}"
      I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale.to_sym : nil
    rescue
      Rails.logger.warn "Failed to find locale from User, using default"
      return nil
    end
  end

  def extract_locale_from_subdomain
    begin
      parsed_locale = request.subdomains.first
      return nil if parsed_locale.nil?
      Rails.logger.debug "Subdomain locale: #{request.subdomains.inspect} -- #{parsed_locale} -- #{I18n.available_locales.inspect}"
      I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale.to_sym : nil
    rescue
      Rails.logger.warn "Failed to find locale from subdomain, using default"
      return nil
    end
  end

  def extract_locale_from_accept_language_header
    begin
      parsed_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first.to_sym
      return nil if parsed_locale.nil?
      Rails.logger.debug "Language header locale: #{parsed_locale} -- #{I18n.available_locales.inspect}"
      I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale.to_sym : nil
    rescue
      Rails.logger.warn "Failed to find locale from language header, using default"
      return nil
    end
  end

  def extract_locale_from_params
    parsed_locale = nil
    parsed_locale ||= params[:fb_locale].to_sym rescue nil
    parsed_locale ||= params[:locale].to_sym rescue nil
    Rails.logger.debug "Params locale: #{parsed_locale} -- #{I18n.available_locales.inspect}"
    return parsed_locale if I18n.available_locales.include?(parsed_locale)
    return nil
  end

  def force_request_format_to_html
    request.format = :html
  end

  def missing_template
    raise if self.formats != [:text]
    Rails.logger.warn "Missing template exception #{request.format} - #{request.fullpath}"
    render :text => "Format Requested Not Acceptable", :status => 406
  end

  def ping
    render :json => true
  end

  private

  def save_origin_url url=nil
    if url.nil?
      ## if it's not an API call, we update the current url in session
      if params[:save_origin_url]==true || (!request.fullpath.match(/^(\/api\/|\/login\/|\/user_images\/|\/admin\/|\/assets\/|\/[A-Za-z\.0-9\-\_]*\/feed)/) && !request.fullpath.match(/(\.js|widget|update|delete|profile)$/) && !request.fullpath.match(/\/profile\.(svg|png)/) )

        if request.fullpath.match(/^\/[A-Za-z\.0-9\-\_]*\/partial/)
          new_url = request.fullpath.gsub(/\/partial\//,"/")
        else
          new_url = request.fullpath
        end

        logger.debug "updating session data with full path at "+new_url
        @origin_url = session[:origin_url]
        if @origin_url.nil?
          @origin_url="/"
        end
        session[:origin_url] =  new_url
      else
        if session[:origin_url].nil? || !request.fullpath.match(/^\/\?/).nil?
          @origin_url = "/"
          logger.debug "session:origin_url is nil"
        else
          @origin_url = session[:origin_url]
        end
        logger.debug "this is an api call, we don't change the origin url from "+@origin_url
      end
    else
      session[:origin_url] = url
      @origin_url = url
    end

    ## if we are asked to ensure login to this page, let's save it if user is not logged
    if !params[:ensure_login].nil? && params[:ensure_login] == "true" && @user.nil?
      Rails.logger.debug "We'll try to log a user and redirect it properly"
    cookies[:redirect_url] = session[:origin_url].gsub("ensure_login=true", "").gsub("?&","?")
    end

    if !cookies[:redirect_url].nil?
      Rails.logger.debug "A redirect_url cookie is present and will override the value for @origin_url"
      @origin_url = cookies[:redirect_url] ## we keep the cookie url by default
    end
  end


  def init_logged_user
    HtmlHelper.set_ssl request.ssl?

    init_logged_user_without_sudo
    throttle_api
    handle_sudo
    begin
      if !@user.nil? then
        lt = Time.now
        I18n.available_locales.each do |locale|
          expire_fragment "#{locale} user_#{@user.id}_home1_0"
          expire_fragment "#{locale} user_#{@user.id}_home1_1"
          expire_fragment "#{locale} user_#{@user.id}_home1_2"
          expire_fragment "#{locale} user_#{@user.id}_home2"
        end
        logger.info "Purging the cache for #{@user.id} took #{(1000*(Time.now-lt)).round(1).to_f} ms"
      end
    rescue
    end
    init_basket
    init_inbox
  end

  def init_logged_user_without_sudo
    #check for token in session else in cookie
    # if valid token is found, @user is instantiated, - if token was taken from cookie token is changed and saved to session and cookie
    logger.debug "root_url: #{root_url}"
    logger.debug "beginning of init_logged_user at #{Time.now.to_f}"
    logger.debug " cookie is : #{cookies.signed[TOKEN]}"
    logger.debug " session is : #{session[TOKEN]}"
    if params[:auth_token].blank? && !params[:token].blank?
      params[:auth_token] = params[:token] ## legacy support
    end
    logger.debug " auth_token param is : #{params[:auth_token]}"
    logger.debug " sudo cookie : #{cookies['sudo']}"
    logger.info " cookies contains : #{cookies.inspect}"
    logger.info " session contains : #{session.inspect}"

    if !(authtoken = AuthTokens.find_by_token(params[:auth_token])).nil? || ( !session[TOKEN].nil? &&  !(authtoken = AuthTokens.find_by_token(session[TOKEN])).nil?  )
      @user = authtoken.user

      begin
        if authtoken.api_key.blank? && !params[:apikey].blank?
          authtoken.api_key = params[:apikey]
          authtoken.save
        end
      rescue
      end
      ##alles klar, we've got an already authentified user
      ##if user is identified by param[:auth_token] we do not care about creating a lasting session, and we definitely don't want to change it at every call
      if @user.nil?
        ##somehow user is not there anymore, let's clean up
        session[TOKEN] = nil
        session[:private] = false
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        redirect_to "/"
        return
      end
      logger.info " User already authentified and exists, id = #{@user.id}, vanity = #{@user.vanity_url}"
      set_locale
      ## check if user is new
      if @user.vanity_url.nil?
        @user = generate_vanity_url @user.first_name, @user.last_name
        @user.save
      end
    else
      if !cookies.signed[TOKEN].nil? && !(authtoken = AuthTokens.find_by_token(cookies.signed[TOKEN])).nil? && authtoken.expires > Time.now
        #we have a cookie, a valid token that has not expired
        @user = authtoken.user
        

        begin
          if authtoken.api_key.blank? && !params[:apikey].blank?
            authtoken.api_key = params[:apikey]
            authtoken.save
          end
        rescue
        end

        ##user is known through cookie - coolio
        ##for security reasons we need to change the token
        if @user.nil?
          logger.info "User has a cookie token but it s not valid"
          ##somehow user is not there anymore, let's clean up
          session[TOKEN] = nil
          session[:private] = false
          cookies.delete TOKEN, domain: COOKIES_DOMAIN
          redirect_to "/"
          return
        end

        logger.info "User auth by cookie - updating tokens number #{authtoken.id} for #{@user.id}"
        session[TOKEN] = authtoken.update_token
        session[:private] = true
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => authtoken.expires, domain: COOKIES_DOMAIN}
        logger.debug "setting new token in coookie from session at #{session[TOKEN]} to cookie at #{cookies.signed[TOKEN]}"
        ##we reset perms just in case next time we need them they'll be checked out
        @user.check_valid_fbtoken
        if @user.vanity_url.nil?
          @user = generate_vanity_url @user.first_name, @user.last_name
          @user.save
        end

      else
        if !cookies.signed[TOKEN].nil? then
          ##user had a wrong cookie
          flash[:notice] = "You have been logged out from this session."
        end
        logger.info "Unknown user - session will be public (aka private=false)"
        @user = nil
        session[TOKEN] = nil
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        logger.debug "cookie deleted"
        session[:private] = false
      end
    end

    logger.debug "end of init_logged_user at #{Time.now.to_f}"

  end

  def register_fb_user_from_token token
    newuser = false
    @graph = Koala::Facebook::API.new(token) # create the graph objet
    profile = @graph.get_object("me")
    logger.debug "User profile number is #{profile["id"]}"
    @user = User.find_or_create_by_fb_id(profile["id"]) { |u|
      u.contact_email = profile["email"]
      u.nickname = "#{profile['first_name']} #{profile['last_name']}".strip
      u.first_name = profile["first_name"]
      u.last_name = profile["last_name"]
      u.preferred_locale = I18n.locale

      u.vanity_url = generate_vanity_url(profile["first_name"], profile["last_name"])
      ###u.vanity_url = nil
      ## VANITY URL will be asked on first login by /login/fb_vanity
      ##

      ## Set default settings
      u.location = "blank"
      begin
        base_url = 'https://api.facebook.com/method/fql.query'
        request = {
          :query => "SELECT current_location FROM user WHERE uid=#{profile["id"]}",
          :format => :json,
          :access_token => token
        }

        begin
          uri = URI.parse(base_url)
          uri.query = request.to_query
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)
          data = response.body
          logger.debug "Got : #{data}"

          decoded_data = JSON.parse(data)
          if decoded_data.count > 0 then
            u.location = Country.where(:cname => decoded_data.first["current_location"]["country"]).ccode.downcase rescue 'blank'
            u.city = decoded_data.first["current_location"]["city"]
          end
        rescue
        end
      rescue
      end

      begin
        location = @graph.get_object(profile["location"]["id"])
        u.lat = location["location"]['latitude']
        u.lng = location["location"]['longitude']
      rescue
      end



      u.settings = "{}" #defaults, may need to be updated to sth more useful...
      u.pict = false;
      u.fb_permissions = nil


      newuser = true
      logger.debug "User did not exist, let's create it"
      session[:ga_track_events].push :category => 'account', :action => 'register', :label => 'Facebook'
    }
    if @user.fbtoken != token
      logger.info "User has a new token, we need to update"
      @user.fbtoken = token
      @user.fb_permissions = nil
      @user.save
    end
    return newuser
  end


  def check_or_create_user_from_fb_token token
    #check if user is in DB else create it
    begin
      newuser = register_fb_user_from_token token
      session[:private] = true

      #check if user exists in DB already

      if !newuser then
        #if user already existed check if user details got updated and update values if needed
        if @user.fbtoken != token then
          #we need to update the token
          @user.fbtoken = token
          @user.fb_permissions = nil
          @user.save
        end
      end

      @user.update_fb_permissions ## everytime we check a user on FB api, we update the permissions

      #@user.fb_permissions = nil
      @user.save
      #now that we've done all that we can finally put da cookie for mama
      authtoken = AuthTokens.create(:user_id => @user.id, :expires => 1.week.from_now)
      begin
        if !params[:apikey].blank?
          authtoken.api_key = params[:apikey]
          authtoken.save
        end
      rescue
      end
      logger.debug "Setting up a new token for #{@user.id}"
      session[TOKEN] = authtoken.update_token
      session[:private] = true
      cookies.delete TOKEN, domain: COOKIES_DOMAIN
      cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => authtoken.expires, domain: COOKIES_DOMAIN}
      logger.debug "User found succesfully - moving on"
      if @user.vanity_url.nil?
        @user = generate_vanity_url @user.first_name, @user.last_name
        @user.save
      end

    rescue Koala::Facebook::APIError
      #TODO maybe token is not valid anymor
      logger.debug "invalid token #{token}"
      session[TOKEN] = nil #delete faulty token
      cookies.delete TOKEN, domain: COOKIES_DOMAIN #delete the info in cookie too, it may be faulty too
      session[:private] = false
      @ga_page_category = "explore"
      render 'login/fb_error', :layout => false
      return true

    rescue Errno::ETIMEDOUT
      ## the FB call timed out
      if @retry.nil?
        @retry = true
        logger.debug "got a timeout - retrying this one time"
        check_or_create_user_from_fb_token token
        return true
      else
        #TODO maybe token is not valid anymor
        logger.debug "invalid token #{token}"
        session[TOKEN] = nil #delete faulty token
        cookies.delete TOKEN, domain: COOKIES_DOMAIN #delete the info in cookie too, it may be faulty too
        session[:private] = false
        @ga_page_category = "explore"
        render 'login/fb_error', :layout => false
        return true
      end
    end
    return false
  end


  def handle_sudo
    @real_user = @user
    begin
      return if @user.nil?
      return if cookies[:sudo].blank?
      new_user = User.find(cookies[:sudo]) rescue nil
      return if new_user.nil?
      if @user.id == new_user.id || @user.admin_rights >= 4 then
        @user = new_user
      elsif Membership.where({:user_id => @user.id, :group_id => new_user.id, :role => 'admin'}).count <= 0 then
        @user = @user #don't change the user
      else
        @user = new_user
      end
    rescue
      api_exception $!, "Issue while evaluating SUDO for #{@user.id} -> #{cookies[:sudo]}"
    end
  end

  def setdive(dive_number)
    @divenumber = dive_number.to_i
    if @divenumber != 1 && @divenumber != 0 then
      @dive = @owner.dives.find_by_id(@divenumber)
      if ((!@user.nil? && !@user.can_edit?(@owner)) || session[:private] == false )  && !@dive.nil? && @dive.privacy == 1
        ## this is a private dive and user is not owner
        session[:errormsg] = "Sorry this dive is not public but feel free to check out other dives from #{@owner.nickname}"
        @divenumber = 0
      end
      if @dive.nil? then
        session[:errormsg] = "Sorry this dive is not available anymore but feel free to check out other dives from #{@owner.nickname}"
        @divenumber = 0
      end
    end
  end

  def prevent_browser_cache
    headers["Pragma"] = "no-cache"
    headers["Cache-Control"] = "must-revalidate"
    headers["Cache-Control"] = "no-cache"
    headers["Cache-Control"] = "no-store"
  end

  def throttle_api
    if !ThrottleApi.allowed?(request, @user) then
      render status: 403, text: 'Rate Limit Exceeded. This incident has been reported to the admins. If you legitimately require to make more API calls, please contact support at diveboard dot com'
      return false
    end
  end

  def merge_fb_user fb_token
    begin
      @graph = Koala::Facebook::API.new(fb_token) # create the graph objet
      profile = @graph.get_object("me")
      if @user.fb_id != profile["id"].to_i && !(user2 = User.find_by_fb_id(profile["id"])).nil?
        #damn there's a user already with that FB_ID ... what a n00b !, we need to move its assets and kill it
        user2.merge_into @user
      end
      @user.fb_id = profile["id"]
      @user.first_name = profile["first_name"]
      @user.last_name = profile["last_name"]
      @user.fbtoken = fb_token
      logger.debug "fb_token added to user #{@user.id}"


      #
      ## VANITY URL will be asked on first login by /login/fb_vanity
      ##

      ## Set default settings
      @user.location = "blank"
      begin
        base_url = 'https://api.facebook.com/method/fql.query'
        request = {
          :query => "SELECT current_location FROM user WHERE uid=#{profile["id"]}",
          :format => :json,
          :access_token => fb_token
        }

        begin
          uri = URI.parse(base_url)
          uri.query = request.to_query
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)
          data = response.body
          logger.debug "Got : #{data}"

          decoded_data = JSON.parse(data)
          if decoded_data.count > 0 then
            @user.location =
            @user.city = decoded_data.first["current_location"]["city"]
          end
        rescue
        end
      rescue
      end

      begin
        location = @graph.get_object(profile["location"]["id"])
        @user.lat = location["location"]['latitude']
        @user.lng = location["location"]['longitude']
      rescue
      end



      @user.save
      #@user.update_fb_permissions
    rescue
      logger.debug "merge_fb_user failed with " + $!.message
      if !@user.fbtoken.blank?
        logger.debug "nilling fbtoken for user id "+@user.id.to_s
        @user.fbtoken = nil
        @user.save
      end
    end
  end





  def update_spot_from_params spot
    ## Update de original spot
    ## Used in ***both*** spot creation wizard and admin and api

    ## will raise plenty of exceptions if the finds of country, location, region fail

    if !params[:name].nil? then
      spot.name = params[:name].titleize
    else
      spot.name = ""
    end
    ##country MUST exist already
    country = Country.find_by_ccode(params[:country])
    spot.country_id = country.id

    ##Location must exist
    location = Location.find_by_name(params[:location])
    if params[:location] != "" && !params[:location].nil? && location.nil?
      location = Location.create(:name => params[:location], :country_id => country.id)
    end
    if location.nil?
      location = Location.find(1)
    end
    spot.location_id = location.id

    if params[:region] == ""
      spot.region_id = nil
    else
      region = Region.find_by_name(params[:region])
      if params[:region] != "" && region.nil?
        region = Region.create(:name => params[:region])
      end
      if !region.nil?
        spot.region_id = region.id
        ##link country/region/location together !
        location.regions << region
        country.regions << region
      end
    end

    spot.lat = params[:lat].to_f
    spot.long = params[:lng].to_f
    begin spot.zoom = params[:zoom].to_i rescue spot.zoom = 9 end
    begin spot.description = params[:description] rescue spot.description = nil end


    ##SPOT Is ready to be saved !
  end

  def check_spot_data
    ## checks the data sent back from the form to create spots
    ## setting zoom between 6 and 12
    if params[:zoom].to_i < 6 then params[:zoom] =6 end
    if params[:zoom].to_i >12 then params[:zoom] =12 end
    if params[:country].nil? ||  Country.find_by_ccode(params[:country].upcase).nil? || params[:lat].to_f.abs > 90 || params[:lng].to_f.abs > 180
      flash[:notice] = "Data was incorrect, DID NOT SAVE"
      raise DBArgumentError.new "Check_spot_data failed"
    end
  end

  def page_version_from_params wiki
    ## this is a generic helper checkign the params[:version] and showing the appropriate revision of a wiki page object

    if params[:version].nil?
      return wiki.page_current
    elsif params[:version] == "current"
      return wiki.page_current
    elsif params[:version] == "latest"
      return wiki.page_latest
    else
      return wiki.get_page params[:version]
    end
  end


  def randomFileNameSuffix (numberOfRandomchars)
    s = ""
    numberOfRandomchars.times { s << (65 + rand(26))  }
    s
  end


  def signup_popup_hidden
    ## we don't want the popup shown by default
    @signup_popup_status = :not_needed
    signup_popup_override_by_params
  end

  def signup_popup_disposable
    ## we DO want the popup shown by default but we let the user
    ## close it and if he does so he won't see it for 24hrs(unless he asks)
    @signup_popup_status = :ask_once
    signup_popup_override_by_params
  end

  def signup_popup_force
    ## we DO want the popup shown by default and you can't dismiss it
    @signup_popup_status = :force_signup
    signup_popup_override_by_params
  end

   def signup_popup_click_count
    ## we DO want the popup shown by default and you can't dismiss it
    @signup_popup_status = :force_count
    @signup_popup_status_max = 3
    signup_popup_override_by_params
  end

  def signup_popup_force_login
    #  we DO want the popup shown by default and you can't dismiss it
    @signup_popup_status = :force_login
    signup_popup_override_by_params
  end

  def signup_popup_force_private
    #  we DO want the popup shown by default and you can't dismiss it and you get a message that telss you you want this
    @signup_popup_status = :force_private
    signup_popup_override_by_params
  end

  def signup_popup_override_by_params
    if params[:force_login].present?
      @signup_popup_status = :force_login
    elsif params[:force_private].present?
      @signup_popup_status = :force_private
    elsif params[:force_signup].present?
      @signup_popup_status = :force_signup
    end
  end


  def api_exception(err, text=nil)
    error_tag = "#{$$}.#{Time.now.to_i}.#{Time.now.usec}"
    logger.error "Call failed in #{params[:controller]}#{params[:action]} : #{err.message}"
    logger.info "Tag for error : #{error_tag}"
    #logger.debug err.backtrace
    request.env['error_tag'] = error_tag
    request.env['exception_notifier.options'] = Rails.application.middleware.find { |klass| klass == ExceptionNotifier }.args.first rescue {}
    text ||= err.message
    begin
      ExceptionNotifier::Notifier.exception_notification(request.env, err).deliver
    rescue
      logger.debug 'Initial exception :'
      logger.debug err.backtrace.join("\n")
      logger.error "EXCEPTION NOTIFICATION by mail FAILED !!!"
      logger.debug $!.message
      logger.debug $!.backtrace.join("\n")
    end
    r = {:json => err.as_json.merge({:success => false, :error => text, :error_tag => error_tag, :user_authentified => !@user.nil?})}
    logger.info "Returning : #{r}"
    return r
  end


  ## helper method to process the udcf files
  def process_export_data (type, uploaded_file, user_id)

    user = User.find(user_id)

    Rails.logger.debug "Starting processing of file : #{uploaded_file.id}"

    export = Divelog.new
    export.from_uploaded_profiles(uploaded_file.id)
    raise DBArgumentError.new "no dives found in file" if export.dives.nil?


    # Constructs the summary of the loaded dives
    dive_summary = []
    export.dives.sort_by{|dive| dive["beginning"]}.each { |dive|
      #check if dive looks like one we already have by date / max depth
      newdive = true
      dive_duplicate_id=nil
      Rails.logger.debug { "Dive read date : "+dive["beginning"].to_s+" depth: "+(dive["maximum_depth"]||0.0).to_s}
      dives = user.dives.where("time_in BETWEEN ? AND ?",dive["beginning"]-25*3600, dive["beginning"]+25*3600)
      dives.each do |divedb|
        if (divedb.maxdepth.to_f - dive["maximum_depth"]).abs < 0.5 then
          newdive = false
          dive_duplicate_id = divedb.shaken_id
          Rails.logger.debug {"Dive "+dive["dive_number_in_export"].to_s+" already exists "}
        end
      end

      Rails.logger.debug "Summary for dive #{dive['dive_number_in_export']} @ #{dive['beginning']} : #{dive['duration']} - #{dive['maximum_depth']}"
      dive_data = {:number => dive["dive_number_in_export"], :date => dive["beginning"].strftime("%Y-%m-%d"), :time => dive["beginning"].strftime("%H:%M"), :duration => ((dive["duration"]||0.0)/60).round, :max_depth => (dive["maximum_depth"]||0.0).round(2).to_f, :mintemp => dive["min_water_temp"], :maxtemp => dive["air_temperature"] || dive["max_water_temp"], :newdive => newdive, :dive_duplicate_id => dive_duplicate_id}
      dive_summary.push dive_data #add to the summary
    }

    dive_summary.sort!{|e,f| f[:date]<=>e[:date]}

    Rails.logger.debug "Number of dives found : #{export.dives.count}"

    parser = Nokogiri::XML(export.initial_data)

    completion_form_url = URI.parse(ROOT_URL)
    completion_form_url.scheme = "https" unless Rails.env.development?
    completion_form_url.path = "/l/bulk"
    completion_form_query = {bulk: 'wizard', profile_id: uploaded_file.id}
    completion_form_query[:auth_token] = params[:auth_token] if params[:auth_token]
    completion_form_url.query = completion_form_query.to_query

    return {:success => "true", :nbdives => "#{export.dives.length}", :dive_summary => dive_summary, :fileid => uploaded_file.id, completion_form_url: completion_form_url.to_s }

  end

  def hash_to_object id
    return BlogPost.fromshake(id) if id.match(/^B/)
    return Dive.fromshake(id) if id.match(/^D/)
    return Spot.fromshake(id) if id.match(/^S/)
    return Location.fromshake(id) if id.match(/^L/)
    return Review.fromshake(id) if id.match(/^RW/)
    return Region.fromshake(id) if id.match(/^R/)
    return Wiki.fromshake(id) if id.match(/^W/)
    return Shop.fromshake(id) if id.match(/^K/)
    return User.fromshake(id) if id.match(/^U/)
    return nil
  end

  def generate_vanity_url *args

    norm_args = []
    args.each do |val|
      norm_args.push val.to_url.gsub(/[^a-zA-Z0-9.\-]/n, '').to_s.downcase unless val.nil?
    end

    suggested_url= norm_args.join(".").downcase
    suggested_url = SecureRandom.urlsafe_base64(20) if suggested_url.blank?

    if User.find_by_vanity_url(suggested_url).nil? then
      vanity_url = suggested_url
    else
      i=2
      vanity_url = suggested_url.downcase+i.to_s
      while !User.find_by_vanity_url(vanity_url).nil?
        i += 1
        vanity_url = suggested_url+i.to_s
      end
    end
    logger.debug "Generated vanity url #{vanity_url}"
    return vanity_url
  end

  def log_user_agent
    Rails.logger.info "User Agent: #{request.env["HTTP_USER_AGENT"]}"
    Rails.logger.info "HTTP Referer: #{request.env["HTTP_REFERER"]}"
  end

  def init_google_analytics
    session[:ga_track_events] ||= [] unless session.nil?
    @custom_analytics = false
    @ga_page_category = "other"
  end

  def init_basket
    @baskets = {}

    #Get the baskets in session
    #TODO: maybe reload baskets from the database ? but then we would need to merge
    if session[:baskets].nil? then
      session[:baskets] = []
    else
      new_basket_ids = []
      session[:baskets].each do |basket_id|
        basket = Basket.find(basket_id) rescue next
        next unless ['open', 'checkout'].include? basket.status
        next unless basket.basket_items.count > 0
        next unless @user.nil? || (@user.nil? && basket.user_id.nil?) || basket.user_id.nil? || basket.user == @user
       # next unless @user.nil? || basket.user_id.nil? || basket.user_id == @user.id
        if !@user.nil? && !basket.nil? && basket.user_id.nil?
          basket.user_id = @user.id
          basket.save
        end

        @baskets[basket.shop_id] = basket
        new_basket_ids.push basket.id
      end
      session[:baskets] = new_basket_ids
    end
  end

  def init_track_events_analytics
    @track_events_analytics = []
    @custom_analytics = false
    @ga_page_category = "other"
  end

end

