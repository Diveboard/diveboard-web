require 'validation_helper'

class XOriginEnabler # :nodoc:
  # http://merbist.com/2011/09/14/how-to-cross-domain-ajax-in-a-ruby-app/
  ## Alternatively we could use : https://github.com/cyu/rack-cors
  ORIGIN_HEADER = "Access-Control-Allow-Origin"

  def initialize(app, accepted_domain="*")
    @app = app
    @accepted_domain = accepted_domain
  end

  def call(env)
    status, header, body = @app.call(env)
    header[ORIGIN_HEADER] = @accepted_domain
    header["Access-Control-Allow-Methods"] = "GET, OPTIONS, POST, DELETE, PUT"
    header["Access-Control-Allow-Headers"] = "X-CSRF-Token,DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type"
    header["Access-Control-Allow-Credentials"] = "true"
    [status, header, body]
  end
end

class ApiController < ApplicationController
  use XOriginEnabler
  before_filter :prevent_browser_cache, :check_api_access_rights


  def check_api_access_rights # :nodoc:
    # checks params[:apikey]
    # TODO ! here we only ensure there is one...
    #raise DBArgumentError.new "invalid apikey" if !ApiKey.validate(params[:apikey])
    begin
      init_logged_user ## try to init @user first
    rescue
      Rails.logger.debug "check_api_access_rights failed #{$!.message}"
      render api_exception $!
      return false
    end

  end

  def check_mobile_update
    #gets platform , version and returns  to_update, update_url and callback
    ## TODO => IMPLEMENT THIS


    to_update = false
    update_url = nil
    callback = nil

    if params[:platform].match(/^ios$/i)
      to_update = (params[:version].to_i < IOS_CURRENT_VERSION)
      if to_update
        to_update = IOS_CURRENT_PACK
        callback = IOS_UPDATE_CALLBACK
      end
    end

    render :json => {
      :success => true,
      :result=>{
        :to_update => to_update,
        :update_url => update_url,
        :callback => callback } }
  end


  #
  # :section: LOGIN_FB
  #

  # [General]
  #  - API url : /api/login_fb
  #  - Logs a user by checking fbtoken + fbid OR email+password
  #  - Gives a token valid for 1 month
  #  - If unregistered user will create an account
  #
  # [Authentication]
  #  - NOT Required
  #  - POST Call
  # [Request - case FB]
  #  - *fbid* : User's Facebook ID
  #  - *fbtoken* : User's Facebook Token (as given by facebook)
  #  - *apikey*: the application's API key
  #  - *assign_vanity_url*: assign vanity url if none
  #  - callback: the callback function (if supplied it will be responded using jsonp)
  # [Response]
  #  - *success* : boolean, false if failure
  #  - error : string defining the error (only present if success==false)
  #  - error_tag : uid of the error (only present if success==false)
  #  - *token* : string with the authentication token to use
  #  - *expiration*: Date when the token expires - 1day (prevent all timezone craze)
  #  - *vanity_url_defined*: boolean , if false, you should ask the user (which must be new) to register a vanity url
  # [Errors]
  #  TODO: document errors
  #
  def login_fb
    begin
      raise DBArgumentError.new "missing fbid or fbtoken" if params[:fbid].blank? || params[:fbtoken].blank?
      # we need to check this token
      logger.debug "checking if token #{params[:fbtoken]} belongs to user #{params[:fbid]}"
      @graph = Koala::Facebook::API.new(params[:fbtoken]) # create the graph objet
      profile= @graph.get_object("me")
      raise DBArgumentError.new "fbid and fbtoken don't match" if profile["id"].to_i != params[:fbid].to_i
      user = User.find_by_fb_id(profile["id"].to_i)
      new_account = false
      if user.blank?
        ## TODO we need to create the user
        ##render :json => {:success => false, :error => "You need to head over divebord.com and create an account first"}
        register_fb_user_from_token params[:fbtoken]
        user = @user
        new_account = true
        @user.update_attribute :preferred_locale, params[:preferred_locale] unless params[:preferred_locale].blank?
        @user.update_attribute :source, params[:source] unless params[:source].blank?
      end

      #assigning vanity if requested
      if user.vanity_url.blank? && params[:assign_vanity_url] then
        idx = ""
        user.vanity_url = generate_vanity_url(profile["first_name"], profile["last_name"], user.shaken_id+idx)
        user.save!
      end

      PasswordReset.registration_ok(user).deliver if new_account && !user.contact_email.blank? ## send welcome email


      if params[:extralong_token] == "true"
        expires = 100.years.from_now
      else
        expires = 1.month.from_now
      end


      authtoken = AuthTokens.create(:user_id => user.id, :expires => expires)
      begin
        authtoken.api_key = params[:apikey]
        authtoken.save
      rescue
      end
      granted = false
      if user.contact_email.blank?
        perms = @graph.get_connections('me','permissions')
        perms.each do |p|
          if p['permission'] == "email"
            if p['status'] == "granted"
              granted = true
              user.contact_email = @graph.get_object("me")['email']
              user.save!
            end
          end
        end
      end
      authtoken.update_token
      logger.debug "Generated token #{authtoken.token} for user #{user.id} #{user.vanity_url}"
      if params[:callback].blank?
        render :json => {:success => true,
          :token => authtoken.token,
          :expiration => (authtoken.expires - 1.day),
          :vanity_url_defined => !user.vanity_url.blank?,
          :units => user.units,
          :preferred_units => user.preferred_units,
          :id => user.shaken_id,
          :new_account => new_account,
          :contact_email => user.contact_email,
          :email_permi => granted,
          :user => user.to_api(:private, :caller => user)
        }
      else
        render :js => {:success => true,
          :token => authtoken.token,
          :expiration => (authtoken.expires - 1.day),
          :callback => params[:callback],
          :vanity_url_defined => !user.vanity_url.blank?,
          :units => user.units,
          :preferred_units => user.preferred_units,
          :id => user.shaken_id,
          :new_account => new_account,
          :contact_email => user.contact_email,
          :email_permi => granted,
          :user => user.to_api(:private, :caller => user)
        }
      end

      # This is to enable web to use these calls to open sessions.
      # This should not be used by any other client.
      if params[:open_session] == 'short' then
        session[TOKEN] = authtoken.token
        session[:private] = true
        logger.debug "adding short-live token to cookie"
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.day.from_now, domain: COOKIES_DOMAIN}
      elsif params[:open_session] == 'long' then
        session[TOKEN] = authtoken.token
        session[:private] = true
        logger.debug "adding long-live token to cookie"
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.month.from_now, domain: COOKIES_DOMAIN}
      end

      return
    rescue DBException => e
      logger.info e.to_s
      logger.debug e.backtrace
      if params[:callback].blank?
        render :json => e.as_json.merge({:success => false})
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => e.as_json.merge({:success => false, :callback => params[:callback]})
      end
    rescue Koala::Facebook::APIError => e
      logger.info e.to_s
      logger.debug e.backtrace
      e2 = DBTechnicalError.new "Facebook login failed, please try again."
      if params[:callback].blank?
        render :json => e2.as_json.merge({:success => false})
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => e.as_json.merge({:success => false, :callback => params[:callback]})
      end
    rescue
      #trace the error
      logger.debug $!.backtrace
      if params[:callback].blank?
        render api_exception $!
      else
        render api_exception $!
      end
      return
    end
  end


  def update_contact_email
    graph = Koala::Facebook::API.new(params[:fbtoken])
    profile= graph.get_object("me")
    user = User.find_by_fb_id(profile["id"].to_i)

    if user.contact_email.blank?
      user.contact_email = graph.get_object("me")['email']
      user.save!

    end
    if user.contact_email != nil
      render :js =>{:success => true}
    else
      render :js => {:success=>false}
    end
  end
  #
  # :section: REGISTER_VANITY_URL
  #

  # [General]
  #  - API url : /api/register_vanity_url
  #  - Register a user's vanity url (typically after a FB Login)
  #
  # [Authentication]
  #  - NOT Required
  #  - POST Call
  # [Request - case FB]
  #  - *token* : User's Diveboard Token (as given by the authentication)
  #  - *apikey*: the application's API key
  #  - *vanity_url* : the new vanity url
  #  - callback: the callback function (if supplied it will be responded using jsonp)
  # [Response]
  #  - *success* : boolean, false if failure
  #  - error : string defining the error (only present if success==false)
  #  - error_tag : uid of the error (only present if success==false)
  # [Errors]
  #  TODO: document errors
  #
  def treasure_hunt
    if @user!=nil
      if !params['campaign_name'].blank? && !params['object_type'].blank? && !params['object_id'].blank?
        @treasure = Treasure.new :user_id=>@user.id, :object_type=>params['object_type'],:object_id=>params['object_id'], :campaign_name=>params['campaign_name']
        @treasure.save!
        render json: {status: "success", :count=>@user.treasures.where(:object_type=>params['object_type']).count}
      else
        render json: {status: "error"}
      end
    end
  end

  def movescount_access
    Rails.logger.debug "Movescount api call"
    if @user!=nil
      if !@user.movescount_email || !@user.movescount_userkey? #if user not nil and hasn't link his movescount
        if !params[:email].blank? && !params[:userkey].blank?
          @user.movescount_email= params[:email] 
          @user.movescount_userkey = params[:userkey]
          Rails.logger.debug "Movescount API"
          @user.save!
          #render json: {status: "success"}
          #render html: '<body><strong>Not Found</strong></body>'.html_safe
          render :text => "Movescount account has successfully been linked.You are going to be redirected"
          #render :html => "<p data=success>Movescount account has successfully been linked.You are going to be redirected</p>".html_safe
        else
          render json: {status: "fail1"}
        end
      else
        render json: {status: "fail2"}
      end
    else
      render json: {status: "fail3"}
    end
  end

  def movescount_dives
    begin
      @divelog = Divelog.new
      @uploaded_profile = @divelog.movescountDiveList @user.id
      @diveList = JSON.parse(@uploaded_profile.data)
      @diveListJSON = {}
      i=0
      @diveListJSON={:fileid => @uploaded_profile.id,:nbdives=> @diveList.count, :dive_summary=>[],:source=>"movescount"}
      Rails.logger.debug "Movescount dives api call #{@diveList.length}"

      @diveList.each do |d|
        Rails.logger.debug "Movescount dives api loop"
        date=d['LocalStartTime'].split("T")[0]
        time=d['LocalStartTime'].split("T")[1].split(":")[0]+":"+d['LocalStartTime'].split("T")[1].split(":")[1]
        duration=(d['Duration']/60).to_i
        max_depth=d['MaxDepth'] 
        max_temp=d['MaxTemp']
        min_temp = d['MinTemp']
          
        newdive = true
        dive_duplicate_id=nil
        dives = @user.dives.where("time_in BETWEEN ? AND ?",Time.parse(date)-25*3600, Time.parse(date)+25*3600)
        dives.each do |divedb|
          if (divedb.duration.to_f - d["Duration"]).abs < 0.5 then
            newdive = false
            dive_duplicate_id = divedb.shaken_id
          end
        end
        @diveListJSON[:dive_summary].push({:date=>date,:time=>time,:duration=>duration,:dive_duplicate_id =>dive_duplicate_id, :max_depth=>max_depth, :maxtemp=>max_temp, :mintemp=>min_temp,:number=>i, :newdive=>newdive,})
        i+=1
      end
      render :json => {:success=>true, :data=>@diveListJSON}
    rescue JSON::ParserError
      @user.movescount_email= nil 
      @user.movescount_userkey = nil
      @user.save!
      render :json => {:success=>false}
    end

  end

  def register_vanity_url
    begin
      raise DBArgumentError.new "missing token" if params[:token].blank?
      user = @user
      raise DBArgumentError.new "Could not find the user" if user.blank?
      ValidationHelper.vanity_url_checker(params[:vanity_url])
      raise DBArgumentError.new "Diveboad URL already used" unless User.find_by_vanity_url(params[:vanity_url]).nil?
      user.vanity_url = params[:vanity_url].downcase
      user.save!

      if params[:callback].blank?
        render :json => {:success => true}
      else
        render :js => {:success => true, :callback => params[:callback]}
      end
      return
    rescue DBException => e
      logger.info e.to_s
      logger.debug e.backtrace
      if params[:callback].blank?
        render :json => e.as_json.merge({:success => false})
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => e.as_json.merge({:success => false, :callback => params[:callback]})
      end
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end


  #
  # :section: LOGIN_email
  #

  # [General]
  #  - API url : /api/login_email
  #  - Logs a user by checking fbtoken + fbid OR email+password
  #  - ives a token valid for 1 month
  #
  # [Authentication]
  #  - NOT Required
  #  - POST Call
  # [Request - case FB]
  #  - *email* : User's login (email)
  #  - *password* : User's password
  #  - *apikey*: the application's API key
  #  - callback: the callback function (if supplied it will be responded using jsonp)
  # [Response]
  #  - *success* : boolean, false if failure
  #  - error : string defining the error (only present if success==false)
  #  - error_tag : uid of the error (only present if success==false)
  #  - *token* : string with the authentication token to use
  #  - *expiration*: Date when the token expires - 1day (prevent all timezone craze)
  # [Errors]
  #  TODO: document errors
  #
  def login_email
    begin
      raise DBArgumentError.new "missing login or password" if params[:email].blank? || params[:password].blank?

      if (user = User.authenticate(params[:email].downcase, params[:password]))==false
        raise DBArgumentError.new "wrong login/password combination"
      end

      if params[:extralong_token] == "true"
        expires = 100.years.from_now
      else
        expires = 1.month.from_now
      end


      authtoken = AuthTokens.create(:user_id => user.id, :expires => expires)
      begin
        authtoken.api_key = params[:apikey]
        authtoken.save
      rescue
      end
      authtoken.update_token
      logger.debug "Generated token #{authtoken.token} for user #{user.id} #{user.vanity_url}"

      # This is to enable web to use these calls to open sessions.
      # This should not be used by any other client.
      if params[:open_session] == 'short' then
        session[TOKEN] = authtoken.token
        session[:private] = true
        logger.debug "adding short-live token to cookie"
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.day.from_now, domain: COOKIES_DOMAIN}
      elsif params[:open_session] == 'long' then
        session[TOKEN] = authtoken.token
        session[:private] = true
        logger.debug "adding long-live token to cookie"
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.month.from_now, domain: COOKIES_DOMAIN}
      end


      if params[:callback].blank?
        render :json => {:success => true,
          :token => authtoken.token,
          :expiration => (authtoken.expires - 1.day),
          :units => user.units,
          :preferred_units => user.preferred_units,
          :user => user.to_api(:private, :caller => user),
          :new_account => false,
          :id => user.shaken_id}
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => {:success => true,
          :token => authtoken.token,
          :expiration => (authtoken.expires - 1.day),
          :callback => params[:callback],
          :units => user.units,
          :preferred_units => user.preferred_units,
          :user => user.to_api(:private, :caller => user),
          :new_account => false,
          :id => user.shaken_id}
      end
      return
    rescue DBException => e
      logger.info e.to_s
      logger.debug e.backtrace
      if params[:callback].blank?
        render :json => e.as_json.merge({:success => false})
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => e.as_json.merge({:success => false, :callback => params[:callback]})
      end
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end


  def reset_password
    begin
      ## forgot my pwd page - our last attempt to kindly as the user to fb login :)
      if (email = params[:email].downcase).nil?
      #we've been called with the email to reset
        success = false
        error = "Missing email"
        error_code = "email_missing"
      else
        begin
          ValidationHelper.check_email_format(params[:email].downcase)

          if (user = User.find_by_email(email)).nil?
            success = false
            error = "No such user"
            error_code = "email_unknown"
          else
            PasswordReset.pass_reset(user).deliver
            success = true
          end
        rescue
          Rails.logger.warn $!.message
          Rails.logger.debug $!.backtrace.join("\n")
          success = false
          error = "Badly formatted email"
          error_code = "email_ill"
        end
      end
      #render "home/register_3", :layout => false
      if params[:callback].blank?
        render :json => {
          :success => success,
          :error => error,
          :error_code => error_code
        }
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => {
          :success => success,
          :error => error,
          :error_code => error_code,
          :callback => params[:callback]
        }
      end
      return
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end


  #
  # :section: register_email
  #

  # [General]
  #  - API url : /api/register_email
  #  - Creates an account for a user
  #  - Gives a token valid for 1 month
  #
  # [Authentication]
  #  - NOT Required
  #  - POST Call
  # [Request - case FB]
  #  - *email* : User's login (email)
  #  - *password* : User's password
  #  - *password_check* : user's password validation
  #  - *vanity_url* : requested vanity_url
  #  - *assign_vanity_url* : boolean - assigns a pseudo random vanity_url if no vanity_url is provided
  #  - *nickname* : requested nickname
  #  - *apikey*: the application's API key
  #  - callback: the callback function (if supplied it will be responded using jsonp)
  # [Response]
  #  - *success* : boolean, false if failure
  #  - error : json array of objects {:error => "error message" ,  :params => "name of the faulty param"}
  #  - *token* : string with the authentication token to use
  #  - *expiration*: Date when the token expires - 1day (prevent all timezone craze)
  # [Errors]
  #  TODO: document errors
  #

  def register_email
    begin
      e = []
      begin
        raise DBArgumentError.new "Email can't be null" if params[:email].blank?
        ValidationHelper.check_email_format(params[:email].downcase)
      rescue
        e << {:error => $!.message, :params => "email"}
      end

      #Checking vanity url
      if !params[:vanity_url].blank? || !params[:assign_vanity_url] then
        begin
          raise DBArgumentError.new "Diveboard url can't be null" if params[:vanity_url].blank?
          ValidationHelper.vanity_url_checker(params[:vanity_url].downcase)
          if !User.find_by_vanity_url(params[:vanity_url]).nil? then e << {:error => "Diveboard URL already in use", :params => "vanity_url", :code => "vanity_used"} end
        rescue
          e << {:error => $!.message, :params => "vanity_url"}
        end
      end

      if !User.find_by_email(params[:email]).nil? then e << {:error => "email already in use", :params => "email", :code => 'email_used'} end
      if params[:password].blank? then e << {:error => "missing password", :params => "password", :code => 'password_length'} end
      if !params[:password_check].nil? && params[:password] != params[:password_check] then e << {:error => "passwords don't match", :params => "password_check", :code => 'password_match'} end
      if params[:nickname].blank? then e << {:error => "missing nickname", :params => "nickname", :code => 'nickname_length'} end
      if !params[:password].blank? && (params[:password].length < 5 || params[:password].length > 20) then e << {:error => "password must be between 5 and 20 characters", :params => "password", :code => 'password_length'} end
      if !params[:nickname].blank? && (params[:nickname].length > 30 || params[:nickname].length < 3)then e << {:error => "nickname must be less than 30 characters and more than 3", :params => "nickname", :code => 'nickname_length'} end


      if e.empty?
        user = User.create {|u|
            u.email = params[:email].downcase
            u.contact_email = params[:email].downcase
            u.nickname = params[:nickname].capitalize
            u.preferred_locale = params[:preferred_locale] unless params[:preferred_locale].blank?
            u.vanity_url = params[:vanity_url].downcase unless params[:vanity_url].blank?
            u.source = ApiKey.where(key: params[:apikey]).first.comment rescue nil
            u.source = params[:source] unless params[:source].blank?
            u.location = "blank"
           }
        #save the hash (do it here it fails above)
        user.password = Password::update(params[:password])
        user.save!
        logger.debug "User created with id #{user.id}"
        PasswordReset.registration_ok(user).deliver ## send him hellp email

        #assigning vanity if requested
        if user.vanity_url.blank? && params[:assign_vanity_url] then
          idx = ""
          if User.where(:vanity_url => user.nickname).count == 0
            new_vanity = user.nickname
          else
            new_vanity = generate_vanity_url(user.nickname, user.shaken_id+idx)
            while User.where(:vanity_url => new_vanity).count > 0 do
              idx = idx.to_i + 1
              new_vanity = generate_vanity_url(user.nickname, user.shaken_id+idx)
            end
          end
          user.vanity_url = new_vanity
          user.save!
        end

        #assigning auth token
        authtoken = AuthTokens.create(:user_id => user.id, :expires => 1.month.from_now)
      begin
        authtoken.api_key = params[:apikey]
        authtoken.save
      rescue
      end
        authtoken.update_token
        logger.debug "Generated token #{authtoken.token} for user #{user.id} #{user.vanity_url}"
        if params[:callback].blank?
          render :json => {:success => true,
            :token => authtoken.token,
            :expiration => (authtoken.expires - 1.day),
            :units => user.units,
            :preferred_units => user.preferred_units,
            :id => user.shaken_id,
            :new_account => true,
            :user => user.to_api(:private, :caller => user)
          }
        else
          render :js => {:success => true,
            :token => authtoken.token,
            :expiration => (authtoken.expires - 1.day),
            :units => user.units,
            :preferred_units => user.preferred_units,
            :callback => params[:callback],
            :id => user.shaken_id,
            :new_account => true,
            :vanity_url_defined => !user.vanity_url.blank?,
            :user => user.to_api(:private, :caller => user)
          }
        end

        # This is to enable web to use these calls to open sessions.
        # This should not be used by any other client.
        if params[:open_session] == 'short' then
          session[TOKEN] = authtoken.token
          session[:private] = true
          logger.debug "adding short-live token to cookie"
          cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.day.from_now, domain: COOKIES_DOMAIN}
        elsif params[:open_session] == 'long' then
          session[TOKEN] = authtoken.token
          session[:private] = true
          logger.debug "adding long-live token to cookie"
          cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.month.from_now, domain: COOKIES_DOMAIN}
        end
      else
        if params[:callback].blank?
          render :json => {:success => false, :errors => e}
        else
          render :js => {:success => false, :errors => e}
        end
      end

    rescue DBException => e
      logger.info e.to_s
      logger.debug e.backtrace
      if params[:callback].blank?
        render :json => e.as_json.merge({:success => false})
      else
        #TODO Alex : test it ! (and then fix it.....)
        render :js => e.as_json.merge({:success => false, :callback => params[:callback]})
      end
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end





  #
  # :section: searchspot
  #
  ##IF logged, will display user spots, otherwise only validated spots


    def searchspot
      #if params.nil? then params = manual_params end #override params for unitests
      begin
        if !params[:q].nil?
          #result = result.where("name LIKE ?", "%#{params[:q]}%")
          @search_text = params[:q].to_s
          if @search_text.length < 3 then
            render :json => DBArgumentError.new("Search parameter is less than 3 characters").as_json.merge({:success => false, :data => []})
            return
          end
        logger.debug "User is nil : #{@user.nil?}"
        result = SearchHelper.spot_text_search (begin @user.id rescue nil end), @search_text

        elsif !params[:lat].nil? && !params[:lng].nil?
          result = SearchHelper.spot_geo_search (begin @user.id rescue nil end), params[:lat].to_f, params[:lng].to_f
        else
          result = []
        end

        resulta = []
        result.each do |r|
          api_data = r.to_api(:public, :caller => @user)
          resulta << {:name => "#{r.name} (#{r.country.cname} - #{r.location.name})", :id => r.id, :data => api_data} unless api_data.nil?
        end
        render :json => {:success => true, :data => resulta, :user_authentified => !@user.nil?}
        return
      rescue
       #trace the error
       logger.debug $!.backtrace
       render api_exception $!
       return
      end
    end

    #
    # :section: searchsimmilarspot
    #
    ##Search spots with the same name, country and location
    
    def searchsimmilarspot
      #if params.nil? then params = manual_params end #override params for unitests
      begin
        if !params[:n].nil? and !params[:c].nil? and !params[:l].nil?
          #result = result.where("name LIKE ?", "%#{params[:q]}%")
          @search_text = params[:n].to_s.downcase
          if @search_text.length < 3 then
            render :json => DBArgumentError.new("Search parameter is less than 3 characters").as_json.merge({:success => false, :data => []})
            return
          end
          @country_name = params[:c].to_s.downcase
          if @country_name.length < 2 then
            render :json => DBArgumentError.new("Search country is less than 2 characters").as_json.merge({:success => false, :data => []})
            return
          end
          @location_name = params[:l].to_s.downcase
          if @location_name.length < 2 then
            render :json => DBArgumentError.new("Search location is less than 2 characters").as_json.merge({:success => false, :data => []})
            return
          end
        logger.debug "User is nil : #{@user.nil?}"
        result = SearchHelper.spot_simmilar_search (begin @user.id rescue nil end), @search_text, @country_name, @location_name
    
        else
          result = []
        end
    
        resulta = []
        result.each do |r|
          api_data = r.to_api(:public, :caller => @user)
          resulta << {:name => "#{r.name} (#{r.country.cname} - #{r.location.name})", :id => r.id, :data => api_data} unless api_data.nil?
        end
        render :json => {:success => true, :data => resulta, :user_authentified => !@user.nil?}
        return
      rescue
       #trace the error
       logger.debug $!.backtrace
       render api_exception $!
       return
      end
    end


  #
  # :section: BULK API
  #


  # This call is a proxy to all the other API calls, but does them all in a single transaction
  #
  # [Authentication]
  #   Mostly required : if any sub-call generates an exception, all operations are rollbacked
  # [Request]
  #   - *requests* : list of hashes containing :
  #     - *call* : api to be called
  #     - *method* : method of call (post, get)
  #     - *params* : parameters for this call
  # [Response]
  #   - *success* : boolean
  #   - *error* : first error message encountered
  #   - *responses* : list of hashes containing :
  #     - *request* : the request hash passed in the original request
  #     - *response* : the response hash as provided by the call
  def bulk_proxy # :nodoc:
    answers = []
    responses = []
    result = {:success => true, :responses => responses}
    Dive.transaction do
      JSON.parse(params[:requests]).each do |request|
        logger.debug "Searching API for #{request.inspect}"
        service = Rails.application.routes.recognize_path( "/api#{request['call']}", :method => request['method'].downcase.to_sym )
        raise ActionController::RoutingError, 'Only API calls can be called' if service[:controller] != 'api'

        logger.debug "Calling function #{service[:action]}_f"
        response = self.send "#{service[:action]}_f", request['params']
        responses.push({:request => request, :response => response})

        if !response[:success] then
          result[:success] = false
          result[:error] = response[:error]
          raise ActiveRecord::Rollback
        end
      end
    end

    render :json => result
  end

  def user_gear_read # :nodoc:
    render :json => user_gear_read_f(params)
  end

  def user_gear_update # :nodoc:
    render :json => user_gear_update_f(params)
  end

  def dive_read # :nodoc:
    render :json => dive_read_f(params)
  end

  def dive_update # :nodoc:
    render :json => dive_update_f(params)
  end

  def user_read_follow
    render :json => user_read_follow_f(params)
  end

  def user_add_follow
    render :json => user_add_follow_f(params)
  end

  def shop_reply_review # :nodoc:
    render :json => shop_reply_review_f(params)
  end

  def invite_buddy # :nodoc:
    render :json => invite_buddy_f(params)
  end


private

  #
  # :section: USER RELATED API
  #

  # Returns the listing of the logged in user own gear
  #
  #
  # [Authentication]
  #  Required
  # [Request]
  #  None
  # [Response]
  #  - *success* : boolean
  #  - *error* : error message only present if success == false
  #  - *user_gear* : list containing for each gear owned by the user all the information about this gear
  # [Errors]
  #  TODO: document errors
  #
  def user_gear_read_f(params) # :nodoc:
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?

      # 2: Param validation
      #no param here

      # 3 : getting things in place
      logger.debug "having : #{@user.user_gears}"
      published_data = @user.user_gears.map {|g| g.to_api :private, :caller => @user}
      published_data.reject! &:nil?
      logger.debug "publishing : #{published_data.inspect}"

      # 4 : rendering the correct template
      return {:success => true, :user_gear => published_data }

    rescue
      #trace the error
      logger.debug $!.backtrace
      #we should not raise the exception (which causes an error 500), but send mail separately...
      return {:success => false, :error => "Exception caught (#{$!})"}
    end

  end

  # Updates the gear owned by the current logged in user
  #
  #
  # [Authentication]
  #  Required
  # [Request]
  #  - *gear* : structure representing the user gear
  #  TODO: document this structure
  # [Response]
  #  - *success* : boolean
  #  - *error* : error message only present if success == false
  #  - *user_gear* : list containing for each gear owned by the user all the information about this gear. This list contains the updated gear
  # [Errors]
  #  TODO: document errors
  #
  def user_gear_update_f(params) # :nodoc:
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?


      # 2: Param validation
      logger.debug JSON.parse('[{"created_at":"2011-06-10T18:09:09-04:00"}]').first["created_at"].to_date+1.day+1.day
      logger.debug "Gear object received : #{JSON.parse(params[:gear]).inspect}"

      filtered_gear = ValidationHelper.validate_and_filter_parameters JSON.parse(params[:gear]), { :class => Array,
                :sub => {
                  :class => Hash,
                  :sub => {
                    'id' => { :class => Fixnum, :presence => false},
                    'category' => { :class => String, :in => DiveGear.categories, :presence => true},
                    'manufacturer' => {:class => String, :presence => true},
                    'class' => {:class => String, :presence => true},
                    'model' => {:class => String, :presence => true},
                    'reference' => { :class => String, :presence => false},
                    'acquisition' => {:class => Date, :presence => false, :convert_if_string => Date.method(:parse)},
                    'auto_feature' => {:class => String, :presence => false, :in => ['never', 'featured', 'other']},
                    'last_revision' => {:class => Date, :presence => false, :convert_if_string => Date.method(:parse)},
                    'pref_order' => { :class => Fixnum, :presence => false}
                  }
                }
              }

      logger.debug "Gear entered after filtering : #{filtered_gear}"

      # 3: getting things in place
      UserGear.transaction do
        user_gear = @user.user_gears.map &:delete
        filtered_gear.each do |gear|
          gear_class = gear.delete('class')
          new_gear = UserGear.new(gear)
          new_gear.user_id = @user.id
          new_gear.id = gear['id'] if gear_class == 'UserGear'    #required because new doesn't store the id...
          raise DBArgumentError.new "Error saving - #{gear}" if !new_gear.save

          # If a DiveGear is getting stored as a UserGear, then we replace it in all the dives
          if gear_class == 'DiveGear' && !gear['id'].nil? then
            old_gear = DiveGear.joins(:dive).where('dives.user_id' => @user.id, :id =>gear['id']).first
            if !old_gear.nil? then
              begin
                l = DiveUsingUserGear.new
                l.dive_id = old_gear.dive_id
                l.user_gear_id = new_gear.id
                l.featured = old_gear.featured
                l.save
                old_gear.delete
              rescue
                log.error "Error moving DiveGear #{old_gear.id} to UserGear #{new_gear.id} : #{$!.to_s}"
              end
            end
          end

          @user.user_gears << new_gear
        end
        @user.save
      end

      # reload is needed here, or else it doesn't remove the deleted gears....
      @user.reload

      # deleting links between dives and user_gears that point to no gear
      (@user.dives.map &:dive_using_user_gears).flatten.reject {|g| !g.user_gear.nil?}.map &:destroy

      # 4: generating the correct view
      return user_gear_read_f(params)

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => "Exception caught"}
    end
  end



  #
  # :section: DIVE RELATED API
  #

  #
  # Gives basic infomations about a dive
  #
  # [Authentication]
  #  Not required : Depending on the privacy of the dive, all information may not be
  #  returned. If a dive is private and is not owned by the requesting user, then an error
  #  is returned.
  # [Request]
  #  - *id* : id of the dive for which to get informations
  # [Response]
  #  - *success* : boolean, false if failure
  #  - *error* : string defining the error (only present if success==false)
  #  - *dive* :  hash containing the information of the dive
  # [Errors]
  #  TODO: document errors
  #
  def dive_read_f(params) # :nodoc:
    begin
      # 1: Authentication check
      # can be called without authentication

      # 2: Param validation
      f_params = ValidationHelper.validate_and_filter_parameters JSON.parse(params), { :class => Hash,
                  :sub => {
                    'id' => { :class => [Fixnum, String], :presence => true}
                  }
                }

      # 3 : getting things in place
      dive = Dive.fromshake(f_params[:id])
      raise DBArgumentError.new 'Impossible to find requested dive' if dive.nil?


      # 4 : rendering the correct template
      if (@user.nil? || @user.id != dive.user.id) && dive.privacy == 1 then
        return {:success => false, :error => "Impossible to find the requested dive"}
      elsif (@user.nil? || @user.id != dive.user.id) && dive.privacy == 0 then
        return {:success => true, :dive => dive.to_api(:public) }
      else
        return {:success => true, :dive => dive.to_api(:private, :caller => @user) }
      end

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => "Exception caught"}
    end
  end


  #
  # Updates basic infomations about a dive
  #
  # [Authentication]
  #  Required
  # [Request]
  #  - *id* : id of the dive to update
  #  - *dive* : information to update. Only present information in request are updated.
  #    - trip_name : assign a trip name to the dive.
  #    - water :
  #    - visibility :
  #    - altitude :
  #    - TODO: diveshop :
  #    - TODO: divebuddy :
  #    - TODO::: gear
  #    - TODO:::location
  #    -
  # [Response]
  #  *success* : boolean, false if failure
  #  *error* : string defining the error (only present if success==false)
  #  *dive* :  hash containing the information of the dive
  # [Errors]
  #  TODO: document errors
  #
  def dive_update_f(params) # :nodoc:
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?

      # 2: Param validation
      logger.debug "Received params : #{params.inspect}"
      f_params = ValidationHelper.validate_and_filter_parameters params, { :class => Hash,
              :key_to_sym => true,
              :sub => {
                :id => { :class => [Fixnum, String] },
                :dive => { :class => Hash,
                    :convert_if_string => JSON.method(:parse),
                    :sub => {
                      'number' => {:class => Fixnum, :presence => false, :nil => true},
                      'trip_name' => { :class => String, :presence => false, :nil => true},
                      'water' => { :class => String, :presence => false, :in => ['salt', 'fresh'], :nil => true },
                      'altitude' => { :class => [Float, Fixnum], :presence => false, :nil => true },
                      'visibility' => { :class => String, :presence => false, :in => ['bad', 'average', 'good', 'excellent'], :nil => true },
                      'spot_id' => {:class => [Fixnum, String], :presence => false, :convert_if_string => :to_i.to_proc},
                      'shop_id' => {:class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc},
                      'dive_reviews' => {:class => Hash, :presence => false, :convert_if_string => JSON.method(:parse)},
                      'guide' => { :class => String, :presence => false, :nil => true },
                      'diveshop' => {
                        :class => Hash, :presence => false, :nil => true, :convert_if_string => JSON.method(:parse),
                        :sub => {
                          'name' => {:class => String, :presence => false},
                          'town' => {:class => String, :presence => false},
                          'country' => {:class => String, :presence => false},
                          'url' => {:class => String, :presence => false}
                        }
                      },
                      'request_shop_signature' => {:class => [TrueClass, FalseClass], :presence => false},
                      'buddies' => {
                        :class => Array, :presence => false, :nil => true, :convert_if_string => JSON.method(:parse),
                        :sub => {
                          :class => Hash,
                          :sub => {
                            'name' => {:class => String, :presence => false, :nil => true},
                            'email' => {:class => String, :presence => false, :nil => true},
                            'picturl' => {:class => String, :presence => false, :nil => true},
                            'fb_id' => {:class => String, :presence => false, :nil => true},
                            'db_id' => {:class => String, :presence => false, :nil => true},
                            'notify' => {:class => [TrueClass, FalseClass], :presence => false, :nil => true}
                          }
                        }
                      },
                      'user_gear' => { :class => Array, :presence => false, :nil => true, :convert_if_string => JSON.method(:parse),
                        :sub => {
                          :class => Hash, :presence => false, :nil => true, :convert_if_string => JSON.method(:parse),
                          :sub => {
                            'id' => {:class => Fixnum},
                            'featured' => {:class => [TrueClass, FalseClass], :presence => true}
                          }
                        }
                      },
                      'dive_gear' => {
                        :class => Array, :presence => false, :nil => true, :convert_if_string => JSON.method(:parse),
                        :sub => {
                          :class => Hash,
                          :sub => {
                            'id' => {:class => [Fixnum, String], :presence => false, :nil => true},
                            'model' => {:class => String, :presence => true},
                            'featured' => {:class => [TrueClass, FalseClass], :presence => true},
                            'category' => {:class => String, :presence => true, :in => DiveGear.categories},
                            'manufacturer' => {:class => String, :presence => true}
                          }
                        }
                      }
                    }
                  }
                }
              }

      # 3 : getting things in place
      logger.debug "Filtered params : #{f_params.inspect}"
      dive = Dive.fromshake(f_params[:id])
      raise DBArgumentError.new 'Impossible to find requested dive' if dive.nil?

      raise DBArgumentError.new 'Dive is not owned by you' unless @user.can_edit?(dive)

      Dive.transaction do
        if f_params[:dive].has_key? 'number' then
          dive.number = f_params[:dive]['number']
        end

        if f_params[:dive].has_key? 'trip_name' then
          dive.trip_name = f_params[:dive]['trip_name']
        end

        if f_params[:dive].has_key? 'water' then
          dive.water = f_params[:dive]['water']
        end

        if f_params[:dive].has_key? 'altitude' then
          dive.altitude = f_params[:dive]['altitude']
        end

        if f_params[:dive].has_key? 'visibility' then
          dive.visibility = f_params[:dive]['visibility']
        end

        if f_params[:dive].has_key? 'diveshop' then
          dive.diveshop = f_params[:dive]['diveshop'].to_json
        end

        if f_params[:dive].has_key? 'shop_id' then
          dive.shop_id = f_params[:dive]['shop_id']
        end

        if f_params[:dive].has_key? 'request_shop_signature' then
          dive.request_shop_signature = f_params[:dive]['request_shop_signature']
        end

        if f_params[:dive].has_key? 'guide' then
          dive.guide = f_params[:dive]['guide']
        end

        if f_params[:dive].has_key? 'buddies' then
          dive.buddies = f_params[:dive]['buddies']
        end

        if f_params[:dive].has_key? 'spot_id' then
          dive.spot_id = f_params[:dive]['spot_id']
        end

        if f_params[:dive].has_key? 'user_gear' then
          UserGear.transaction do
            dive.dive_using_user_gears.map &:delete

            f_params[:dive]['user_gear'].each do |gear|
              user_gear = UserGear.find(gear['id'])
              raise DBArgumentError.new "Gear #{gear['id']} does not exists or is not owned by you" if user_gear.nil? || user_gear.user_id != dive.user_id
              l = DiveUsingUserGear.new
              l.user_gear_id = user_gear.id
              l.dive_id = dive.id
              l.featured = gear['featured']
              l.save!
            end
          end
        end

        if f_params[:dive].has_key? 'dive_gear' then
          logger.debug 'entering dive_gear update'
          DiveGear.transaction do
            dive.dive_gears.map &:delete
            logger.debug 'deleted'

            f_params[:dive]['dive_gear'].each do |gear|
              logger.debug gear.inspect
              obj = DiveGear.new(gear);
              obj.id = gear['id']
              logger.debug obj.inspect
              dive.dive_gears << obj
              obj.save!
            end
          end
        end

        dive.save!
      end

      # 4 : rendering the correct template
      dive.reload
      return {:success => true, :dive => dive.to_api(:private, :caller => @user) }

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => $!.to_s}
    end
  end








  #
  # adds an activity_following for the user. usually only one of the ids in the request
  #
  # [Authentication]
  #  Required
  # [Request]
  #   optional parameters to check if the current users is folowing an item:
  #      - *user_id* : integer, user id to follow
  #      - *dive_id* : integer, dive id to follow
  #      - *picture_id* : integer, picture id to follow
  #      - *spot_id* : integer, spot id to follow
  #      - *location_id* : integer, location id to follow
  #      - *region_id* : integer, region id to follow
  #      - *country_id* : integer, country id to follow
  #      - *shop_id* : integer, shop id to follow
  # [Response]
  #  *success* : boolean, false if failure
  #  *error* : string defining the error (only present if success==false)
  #  *following* :  hash containing the information of activities followed
  #  *followed* : in case parameters where passed, boolean telling if the elemnt is followed or not
  #  *excluded* : in case parameters where passed, boolean telling if the elemnt is excluded or not
  # [Errors]
  #  TODO: document errors
  #
  def user_read_follow_f(params)
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?

      # 2: Param validation
      logger.debug "Received params : #{params.inspect}"
      f_params = ValidationHelper.validate_and_filter_parameters params.to_hash, { :class => Hash,
              :key_to_sym => true,
              :sub => {
                :user_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :dive_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :picture_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :shop_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :location_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :region_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :country_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :spot_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc }
                }
              }

      if f_params[:user_id].nil? && f_params[:dive_id].nil? && f_params[:picture_id].nil? && f_params[:shop_id].nil? && f_params[:spot_id].nil? && f_params[:location_id].nil? && f_params[:region_id].nil? && f_params[:country_id].nil?then
        return {:success => true, :following => ActivityFollowing.where(:follower_id => @user.id) }
      end

      f_params[:follower_id] = @user.id
      thread = ActivityFollowing.where(f_params).first
      return {:success => true, :followed => !thread.nil? && !thread.exclude, :excluded => !thread.nil? && thread.exclude, :following => thread }

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => $!.to_s}
    end
  end



  #
  # adds an activity_following for the user. usually only one of the ids in the request
  #
  # [Authentication]
  #  Required
  # [Request]
  #  - *do* : string, tells what to do either 'add' or 'remove'
  #  - *user_id* : integer, user id to follow
  #  - *dive_id* : integer, dive id to follow
  #  - *picture_id* : integer, picture id to follow
  #  - *spot_id* : integer, spot id to follow
  #  - *location_id* : integer, location id to follow
  #  - *region_id* : integer, region id to follow
  #  - *country_id* : integer, country id to follow
  #  - *shop_id* : integer, shop id to follow
  #  - *exclude* : boolean, specify if the matching activities should be included or excluded from the feed (default is to include: false)
  # [Response]
  #  *success* : boolean, false if failure
  #  *error* : string defining the error (only present if success==false)
  #  *following* :  hash containing the information of activities followed
  # [Errors]
  #  TODO: document errors
  #
  def user_add_follow_f(params)
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?

      # 2: Param validation
      logger.debug "Received params : #{params.inspect}"
      f_params = ValidationHelper.validate_and_filter_parameters params.to_hash, { :class => Hash,
              :key_to_sym => true,
              :sub => {
                :do => {:class => String, :presence => true, :in => ['add', 'remove'] },
                :user_id =>    { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :dive_id =>    { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :picture_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :shop_id =>    { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :spot_id =>    { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :location_id =>{ :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :region_id =>  { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :country_id => { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc },
                :exclude =>    { :class => [TrueClass, FalseClass], :presence => false }
                }
              }

      # 3 : getting things in place
      logger.debug "Filtered params : #{f_params.inspect}"
      [:user_id , :dive_id , :picture_id, :shop_id , :spot_id , :location_id, :region_id , :country_id].each do |key|
        f_params[key] ||= nil
      end
      logger.debug "Filtered params with default: #{f_params.inspect}"

      f_params[:follower_id] = @user.id
      f_params[:exclude] = false if f_params[:exclude].nil?
      ActivityFollowing.where(f_params.except(:do)).map &:destroy
      ActivityFollowing.create(f_params.except(:do)) unless f_params[:do] == 'remove'

      # 4 : rendering the correct template
      return {:success => true, :following => ActivityFollowing.where(:follower_id => @user.id) }

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => $!.to_s}
    end
  end



  #
  # Allows a shop to reply to a review. This currently doesn't fit the
  # API V2 framework since with the V2, either you can edit every attributes
  # either you cannot edit anything on a given object.
  #
  # [Authentication]
  #  Required
  # [Request]
  #  - *review_id* : integer, review id to comment
  #  - *reply* : text, reply to the review
  # [Response]
  #  *success* : boolean, false if failure
  #  *error* : string defining the error (only present if success==false)
  #  *result* : updated review object
  # [Errors]
  #  TODO: document errors
  #
  def shop_reply_review_f(params)
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?
      ##PREPARE_PLANS
      raise DBArgumentError.new "You must have a plan to reply on reviews" unless @user.admin_rights >= 4

      # 2: Param validation
      logger.debug "Received params : #{params.inspect}"
      f_params = ValidationHelper.validate_and_filter_parameters params.to_hash, { :class => Hash,
              :key_to_sym => true,
              :sub => {
                :reply => {:class => String, :presence => true },
                :review_id =>    { :class => Fixnum, :presence => true, :convert_if_string => :to_i.to_proc }
                }
              }

      # 3 : getting things in place
      review = Review.find(f_params[:review_id])
      allowed = review.shop.is_private_for? :caller => @user

      raise DBArgumentError.new "You don't have the rights to leave replies to reviews for this shop" if !allowed

      review.reply = f_params[:reply]
      review.save!

      # 4 : rendering the correct template
      return {:success => true, :result => review.to_api(:public)}

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => $!.to_s}
    end
  end


  #
  # Send an invitation to a buddy
  #
  # [Authentication]
  #  Required
  # [Request]
  #  - *buddy_id* : integer, review id to comment
  # [Response]
  #  *success* : boolean, false if failure
  #  *error* : string defining the error (only present if success==false)
  #  *result* : updated review object
  # [Errors]
  #  TODO: document errors
  #
  def invite_buddy_f(params)
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?

      # 2: Param validation
      logger.debug "Received params : #{params.inspect}"
      f_params = ValidationHelper.validate_and_filter_parameters params.to_hash, { :class => Hash,
              :key_to_sym => true,
              :sub => {
                :bulk_email =>  { :class => String, :presence => false, :nil => false},
                :external_user_id =>    { :class => Fixnum, :presence => false, :convert_if_string => :to_i.to_proc, :nil => false },
                :email =>    { :class => String, :presence => false, :nil => false },
                :nickname =>    { :class => String, :presence => false, :nil => false },
                }
              }

      # 3 : getting things in place
      if f_params[:bulk_email] then
        buddies = ExternalUser.bulk_create_from_emails @user, f_params[:bulk_email]
        sent = 0
        count = 0
        buddies.each do |buddy|
          link = UsersBuddy.create :user_id => @user.id, :buddy_type => buddy.class.name, :buddy_id => buddy.id
          count += 1
          if buddy.is_a? ExternalUser then
            link.invite!
            sent+=1
          end
        end
        return {:success => true, :result => {:sent => sent, :found => count}}

      elsif f_params[:external_user_id] then
        link = @user.users_buddies.where(:buddy_type => 'ExternalUser', :buddy_id => f_params[:external_user_id]).first
        raise DBArgumentError.new "You don't have access to user #{f_params[:external_user_id]}" if link.nil?
        if !link.buddy.fb_id.nil? then
          link.invited_at = Time.now
          link.save!
        elsif !link.buddy.email.blank? then
          link.invite!
        elsif f_params[:email].blank? then
          raise DBArgumentError.new "No email known for contact"
        else
          u = link.buddy
          u.email = f_params[:email]
          u.save!
          link.invite!
        end

      elsif !f_params[:email].blank?
        buddy = ExternalUser.find_or_create @user, {'name' => f_params[:nickname], 'email' => f_params[:email]}
        if buddy.is_a? User then
          user.db_buddies << buddy
        else
          link = UsersExternalBuddy.create :user_id => @user.id, :external_user_id => buddy.id
          link.invite!
        end
      else
        raise DBArgumentError.new "You must provide external_user_id or email or bulk_email"
      end

      # 4 : rendering the correct template
      return {:success => true}

    rescue DBException => e
      logger.info "ArgumentError : #{e.to_s}"
      logger.debug e.backtrace
      return {:success => false, :error => e.to_s}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      return {:success => false, :error => $!.to_s}
    end
  end


public

  def widget_update
    raise DBArgumentError.new "You must be authenticated" if @user.nil?
    raise DBArgumentError.new "You must supply 'page_type' with value 'Shop'" unless params[:page_type] == 'Shop'
    shop = Shop.find(params[:page_id]) rescue nil
    raise DBArgumentError.new "Unknown shop page for page_id=#{params[:page_id]}" if shop.nil?
    raise DBArgumentError.new "You must supply some 'contents'" if params[:contents].nil?

    raise DBArgumentError.new "You don't have the rights on this page" unless shop.is_private_for?({:caller => @user})

    contents = JSON.parse(params[:contents]) rescue nil
    raise DBArgumentError.new "You must supply some valid JSON 'contents'" if contents.nil?

    modified_set = params[:set]
    raise DBArgumentError.new "You must supply a set to modify (either default or custom)" unless ['default', 'custom'].include?(modified_set)
    raise DBArgumentError.new "You don't have the rights to edit the set #{modified_set}" if modified_set == 'custom' && !shop.can_manage_widgets?

    previous_widgets_in_use = shop.widgets.map do |a,b| b end .flatten.map(&:widget).uniq

    ShopWidget.transaction do
      position = 0
      new_links = []
      contents.each do |column|
        realm = column['realm']
        colnum = column['column']
        next unless Shop::EDITABLE_REALMS.include? realm

        column['widgets'].each do |shop_widget|

          widget_class_name = shop_widget['class_name']
          widget_id = shop_widget['id']
          widget_data = shop_widget['data']

          widget_klass = widget_class_name.constantize rescue nil
          raise DBArgumentError.new "Invalid widget class_name (#{widget_class_name})" if widget_klass.nil?
          raise DBArgumentError.new "You can only modify Widgets here...." unless widget_klass < Widget

          if widget_id.blank? then
            widget = widget_klass.new
          else
            widget = widget_klass.find(widget_id) rescue nil
            raise DBArgumentError.new "Unknown widget #{widget_class_name}(#{widget_id})" if widget.nil?
            raise DBArgumentError.new "You do not own that widget" unless widget.shop_owner == shop
          end

          if !widget_data.nil? then
            widget.update_widget widget_data, shop
            widget.save!
          elsif widget.id.nil?
            widget.save!
          end

          #Draft the disposition of the pages widgets
          link = ShopWidget.new :shop_id => shop.id, :widget_type => widget.class.name, :widget_id => widget.id, :realm => realm, :set => modified_set, :column => colnum, :position => position
          position += 1
          new_links.push link unless colnum.nil?
        end
      end

      # enforcing the new disposition
      if modified_set == 'custom' then
        ShopWidget.where(:shop_id => shop.id, :set => modified_set, :realm => Shop::EDITABLE_REALMS).each &:delete
        new_links.each &:save!
        new_widgets_in_use = Shop.find(params[:page_id]).widgets.map do |a,b| b end .flatten.map(&:widget).uniq
          Rails.logger.debug "#{previous_widgets_in_use.inspect}"
          Rails.logger.debug "#{new_widgets_in_use.inspect}"
        (previous_widgets_in_use - new_widgets_in_use).each &:destroy
      end
    end

    render :json => {:success => true }

  end

  def json_file_version version, filepath
    # begin
    #   urlpath = "/plugin/#{version}/#{filepath}"
    #   file = File.new("public/plugin/#{version}/#{filepath}")
      return {version: version, url: "http://#{ROOT_DOMAIN}/#{filepath}" }
    # rescue
    #   logger.warn "File not found for versions api : #{urlpath}"
    #   return {error: "not found"}
    # end
  end

  def versions
    case params[:component]
    when 'agent_win32' then render :json => json_file_version("20141029", "about/import")
    when 'agent_osx' then render :json => json_file_version("20141029", "about/import")
    when 'agent_linux' then render :json => json_file_version("20141029", "about/import")
    else render :json => {error: "not found"}
    end
  end


  def review_vote_create_or_update
    begin
      raise "User must be authenticated" if @user.nil?
      raise "A review id must be provided" if params[:id].blank?
      raise "A vote must be placed on an existing review" if Review.find(params[:id]).nil?
      vote = ReviewVote.where({user_id: @user.id, review_id: params[:id]}).first
      if vote.nil? then
        vote = ReviewVote.create({user_id: @user.id, review_id: params[:id], vote: params[:vote]})
      else
        vote.vote = params[:vote]
        vote.save!
      end
      render json: {success: true, result: vote.to_api(params[:public], {caller: @user})}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def review_vote_read
    begin
      raise "User must be authenticated" if @user.nil?
      raise "A review id must be provided" if params[:id].blank?
      raise "A vote must be placed on an existing review" if Review.find(params[:id]).nil?
      vote = ReviewVote.where({user_id: @user.id, review_id: params[:id]}).first
      vote = ReviewVote.new({user_id: @user.id, review_id: params[:id]}) if vote.nil?
      render json: {success: true, result: vote.to_api(params[:public], {caller: @user})}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def review_vote_delete
    begin
      raise "User must be authenticated" if @user.nil?
      raise "A review id must be provided" if params[:id].blank?
      raise "A vote must be placed on an existing review" if Review.find(params[:id]).nil?
      vote = ReviewVote.where({user_id: @user.id, review_id: params[:id]}).first
      vote.delete unless vote.nil?
      render json: {success: true}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end



  #####
  #####
  ##### API V2
  #####
  #####
  def api_v2
    begin
      arg = nil
      if params[:type].nil? then
        raise DBArgumentError.new "I need to know what kind of stuff you want me to find/update ! type is not known : '#{params[:type]}'"
      else
        k = params[:type].to_s.classify.constantize
      end

      #Setting the required locale from params
      if params.include? :locale then
        l = params[:locale].to_sym
        l = nil unless I18n.available_locales.include?(l)
        I18n.locale = l || I18n.default_locale
      end

      if params.include? :arg then
        arg = JSON.parse(params[:arg])
      elsif params.include? :id then
        case params[:type]
        when :user
          if params[:id] == 'me' && !@user.nil? then
            arg = {'id'=> @user.id}
          elsif params[:id] == 'me' && !@user.nil? then
            raise DBArgumentError.new "You must be authenfied to use the 'me' alias"
          else
            arg = {'id'=> User.idfromshake(params[:id])}
          end
        when :dive
          arg = {'id'=> Dive.idfromshake(params[:id])}
        when :spot
          arg = {'id'=> Spot.idfromshake(params[:id])}
        when :country
          arg = {'id'=> begin Country.where('id=:id or ccode=:id', :id => params[:id]).first.id rescue nil end}
        else
          arg = {'id'=> params[:id]}
        end
      else
        render :json => {:success => false, :error => [ DBArgumentError.new("What do you want me to do ? you should specify 'arg'") ], :user_authentified => !@user.nil? }
        return
      end

      logger.debug "API #{params[:type]} called by user #{@user.id rescue 'unknown'} #{@user.nickname rescue nil}"

      ret=nil
      #We're creating a transaction here so that all api calls are done in an atomic way
      k.transaction do
        ret = k.create_or_update_from_api(arg, :caller => @user, :apikey => params[:apikey])
      end
      ret[:success] = true

      #handling arrays and single values for flavours
      if params[:flavour].nil? then
        flavour = ['public']
      elsif params[:flavour].is_a? Array then
        flavour = params[:flavour]
      else
        flavour = params[:flavour].split(',')
      end
      flavour.map! &:strip
      flavour.reject &:empty?
      flavour = ['public'] if flavour.empty?
      flavour.map! &:to_sym
      logger.debug flavour.inspect

      options = { :private => false}
      if @user then
        options[:caller] = @user
      end
      json = nil
      json = ret[:target].to_api(flavour, options) unless !ret[:target].respond_to?(:to_api)
      result = {:success => true, :error => ret[:error], :result => json, :user_authentified => !@user.nil? }
      logger.debug "API result : #{result}"
      render :json => result
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def api_v2_delete
    begin
      arg = nil
      if params[:type].nil?  then
        raise DBArgumentError.new "I need to know what kind of stuff you want me to delete !"
      else
        k = params[:type].to_s.classify.constantize
      end

      if params.include? :arg then
        arg = JSON.parse(params[:arg])
      elsif params.include? :id then
        case params[:type]
        when :user
          if params[:id] == 'me' && !@user.nil? then
            arg = {'id'=> @user.id}
          else
            arg = {'id'=> User.idfromshake(params[:id])}
          end
        when :dive
          arg = {'id'=> Dive.idfromshake(params[:id])}
        when :spot
          arg = {'id'=> Spot.idfromshake(params[:id])}
        else
          arg = {'id'=> params[:id]}
        end
      else
        render :json => {:success => false, :error => [ DBArgumentError.new("What do you want me to do ? you should specify 'arg'") ], :user_authentified => !@user.nil? }
        return
      end

      options = { :private => false}
      if @user then
        options[:caller] = @user
      end

      #handling arrays and single values for flavours
      if params[:flavour].nil? then
        flavour = ['public']
      elsif params[:flavour].is_a? Array then
        flavour = params[:flavour]
      else
        flavour = params[:flavour].split(',')
      end
      flavour.map! &:strip
      flavour.reject &:empty?
      flavour = ['public'] if flavour.empty?
      flavour.map! &:to_sym
      logger.debug flavour.inspect


      logger.debug "API DELETE #{params[:type]} called by user #{@user.id rescue 'unknown'} #{@user.nickname rescue nil}"

      object = k.find(arg['id'])

      if !object.is_private_for? options then
        logger.info "API DELETE denied for #{params[:type]} #{object.id} called by user #{@user.id rescue 'unknown'} #{@user.nickname rescue nil}"
        render :json => {:success => false, :error => [ DBArgumentError.new("Forbidden") ], :user_authentified => !@user.nil?}
        return
      end

      #We're creating a transaction here so that all api calls are done in an atomic way
      k.transaction do
        object.destroy
      end

      json = nil
      json = k.find(arg['id']).to_api(flavour, options) rescue nil
      result = {:success => true, :result => json, :error => [], :user_authentified => !@user.nil? }
      logger.debug "API result : #{result}"
      render :json => result
    rescue ActiveRecord::RecordNotFound => e
      logger.debug "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render :json => {:success => false, :error => [ DBArgumentError.new("Element not found", classname: k, id: arg['id']) ], :user_authentified => !@user.nil?}
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def api_v2_new
    begin
      arg = nil
      if params[:type].nil?  then
        raise DBArgumentError.new "I need to know what kind of stuff you want me to delete !"
      else
        k = params[:type].to_s.classify.constantize
      end

      Rails.logger.debug("ARG -------------------------------------------")
      Rails.logger.debug(params[:arg])
      Rails.logger.debug("-----------------------------------------------")

      if params.include? :arg then
        arg = JSON.parse(params[:arg])
      end

      options = { :private => false}
      if @user then
        options[:caller] = @user
      end

      #handling arrays and single values for flavours
      if params[:flavour].nil? then
        flavour = ['public']
      elsif params[:flavour].is_a? Array then
        flavour = params[:flavour]
      else
        flavour = params[:flavour].split(',')
      end
      flavour.map! &:strip
      flavour.reject &:empty?
      flavour = ['public'] if flavour.empty?
      flavour.map! &:to_sym
      logger.debug flavour.inspect


      logger.debug "API NEW #{params[:type]} called by user #{@user.id rescue 'unknown'} #{@user.nickname rescue nil}"

      json = nil
      json = k.new.to_api(flavour, options)
      result = {:success => true, :result => json, :user_authentified => !@user.nil? }
      logger.debug "API result : #{result}"
      render :json => result
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def api_v2_search
    begin
      arg = nil
      if params[:type].nil?  then
        raise DBArgumentError.new "I need to know what kind of stuff you want me to search !"
      else
        k = params[:type].to_s.classify.constantize
      end

      options = { :private => false}
      if @user then
        options[:caller] = @user
      end


      search_options = {:limit => 20, :start_id => 0}
      if params.include? :arg then
        search_options[:filter] = ActiveSupport::JSON.decode(params[:arg])
      end

      if params[:limit] && params[:limit].to_i > 0 && params[:limit].to_i < 50 then
        search_options[:limit] = params[:limit].to_i
      end

      if params[:start_id] && params[:start_id].to_i >= 0 then
        search_options[:start_id] = params[:start_id].to_i
      end

      if params[:order].nil? then
        search_options[:order] = []
      elsif params[:order].is_a? Array then
        search_options[:order] = params[:order]
      else
        search_options[:order] = params[:order].split(',')
      end

      #handling arrays and single values for flavours
      if params[:flavour].nil? then
        flavour = ['public']
      elsif params[:flavour].is_a? Array then
        flavour = params[:flavour]
      else
        flavour = params[:flavour].split(',')
      end
      flavour.map! &:strip
      flavour.reject &:empty?
      flavour = ['public'] if flavour.empty?
      flavour.map! &:to_sym
      logger.debug flavour.inspect

      logger.debug "API SEARCH #{params[:type]} called by user #{@user.id rescue 'unknown'} #{@user.nickname rescue nil}"

      search = k.search_for_api(search_options, flavour, options)

      result = {:success => true, :result => search[:result], :next_start_id => search[:next_start_id], :count => search[:count],:user_authentified => !@user.nil? }
      logger.debug "API result : #{result}"
      render :json => result
    rescue
      logger.info "Exception caught : #{$!.to_s}"
      logger.debug $!.backtrace
      render api_exception $!
    end
  end

  def valid_email(value)
    begin
      return false if value == ''
      parsed = Mail::Address.new(value)
      return parsed.address == value && parsed.local != parsed.address
    rescue Mail::Field::ParseError
      return false
    end
  end

  # API for external subscribe to newsletter
  def api_v2_newsletter
    # Validate the email format
    if valid_email(params[:email]) == false
      result = {:success => false, :error => "Invalid email"}
      render :json => result
      return
    end
    # Check if the email already exist in Users database
    user = User.where(email: params[:email])
    if user.count.zero?
      # If the email doesn't exist in Users database
      # Find if the email already exist in ExternalUser database
      user = ExternalUser.where(:email => params[:email])
      if user.count.zero?
        # If the email also doesn't exist in ExternalUser database
        # Create the external user and save it
        user = ExternalUser.create(:email => params[:email])
        user.save
      else
        user = user[0]
      end
      # Create or update a EmailSubscription entry to the database
      newsletter = EmailSubscription.find_or_create_by(:scope => :newsletter_email, :recipient_type => :ExternalUser, :recipient_id => user.id)
      # Update the subscribed flag
      newsletter.subscribed = 1
      # Save it to EmailSubscription database
      newsletter.save
      # End of process successful !
    else
      # Else the email already exist in Users database
      # Check if the user is already in EmailSubscription database, if not create it
      newsletter = EmailSubscription.find_or_create_by(:scope => :newsletter_email, :recipient_type => :User, :recipient_id => user[0].id)
      # Update the subscribed flag
      newsletter.subscribed = 1
      # Save it to EmailSubscription database
      newsletter.save
      # End of process successful !
    end
    # Render JSON output
    result = {:success => true, :email => params[:email]}
    render :json => result
  end


  def contest
    begin
      raise DBArgumentError.new "This API needs authentication" if @user.nil?
      raise DBArgumentError.new "Missing params" if params["object_id"].blank?
      raise DBArgumentError.new "Missing params" if params["object_type"].blank?
      raise DBArgumentError.new "Missing params" if params["campaign_name"].blank?

      c = Treasure.new
      c.object_id = params["object_id"].to_i
      c.object_type = params["object_type"]
      c.campaign_name = params["campaign_name"]
      c.user_id = @user.id
      c.save
      result = {:success => true}
      render :json => result
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end



  def report_content
    ##API endpoint to report stuff that are not OK
    begin
      # 1: Authentication check
      raise DBArgumentError.new "This API needs authentication" if @user.nil?
      raise DBArgumentError.new "No object id has been provided" if params["id"].blank?
      raise DBArgumentError.new "No entry type has been provided" if params["type"].blank?
      raise DBArgumentError.new "No explanation of the issue has been provided" if params["text"].blank?
      raise DBArgumentError.new "Cannot identify the object" if hash_to_object(params["id"]).nil?
      obj = hash_to_object(params["id"])

      c = ContentFlag.new
        c.type = params["type"]
        c.object_type = obj.class.to_s
        c.object_id = obj.id
        c.data = params["text"]
        c.user_id = @user.id
      c.save!
      render :json => {:success => true}
      return
    rescue
      #trace the error
      logger.debug $!.backtrace
      render api_exception $!
      return
    end
  end


  def api_v2_options
    #headers need to be sent all the time anyway so are in XOriginEnabler
    head :ok
  end


  def templates
    template_name = params[:template_name]
    render :text => "Invalid template" unless template_name.match(/^[a-zA-Z0-9_-]+$/)
    render "templates/#{template_name}" , :layout => nil, :content_type => 'text/html'
  end
end
