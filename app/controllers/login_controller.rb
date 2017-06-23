class LoginController < ApplicationController
  before_filter :init_oauth, :save_origin_url
  before_filter :init_logged_user, :except => :callback
  respond_to :html, :json # means that by default we reply with html
  #define the proper layout

  def user_login
    #login with user & Password
    #we're coming from the login page, let's set up the snuff
    begin
     if (@user = User.authenticate(params[:user]["email"].downcase, params[:user]["password"]))==false
        logger.debug "Wrong Login/pwd"
        session[TOKEN] = nil
        session[:private] = false
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        logger.debug "User not found - with #{params[:user]["email"].downcase} #{params[:user]["password"].downcase}"
        redirectme =  false
        email_exists = (User.find_by_email(params[:user]["email"].downcase) != nil)
        if email_exists
          errormsg =  "Wrong password"
        else
          errormsg =  "No such login"
        end
      else
        logger.debug "Login / pwd OK - @user instantiated"
        if params["token"]=="1" ||  params["token"]=="on" then
          authtoken = AuthTokens.create(:user_id => @user.id, :expires =>  1.month.from_now)
          logger.debug "adding long-live token to cookie"
          session[TOKEN] = authtoken.update_token
          session[:private] = true
          
          logger.debug "Deleting cookie token #{TOKEN.to_s} for domain #{COOKIES_DOMAIN}"
          cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.month.from_now, domain: COOKIES_DOMAIN}

        else
          authtoken = AuthTokens.create(:user_id => @user.id, :expires => 1.day.from_now)
          logger.debug "adding short-live token to cookie"
          session[TOKEN] = authtoken.update_token
          session[:private] = true
        
          logger.debug "Deleting cookie token #{TOKEN.to_s} for domain #{COOKIES_DOMAIN}"
          cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => 1.day.from_now, domain: COOKIES_DOMAIN}

        end

       

        logger.debug "User found succesfully - moving to the origin_url page #{@origin_url} page token at #{session[TOKEN]}"
        @user.check_valid_fbtoken ## we check tokens also for users with login/pwd
        if @origin_url == "/"
          redirectme =  "/#{@user.vanity_url}"
        else
          redirectme = @origin_url
        end
      end
    rescue
      redirectme = false
      email_exists = false
      errormsg = "Wrong or missing arguments"
    end


    respond_to do |format|
      format.html{
          if !redirectme
            redirect_to "/", :notice => errormsg
            return
          else
            redirect_to redirectme
            return
          end
      }
      format.json{
        if !redirectme
          render :json => { :success => false, :error => errormsg, :emailexists => email_exists}
          return
        else
          render :json => {:success => true, :redirect_to => redirectme}
          return
        end
      }
    end

  end

  def widget_login
    session[:utm_campaign] = params[:partner]
    render 'sign_up_widget', :layout => nil, locals: {partner: params[:partner]}
  end


  def pwd_reset
    params["help"]="pwdreset"
    ## if pwd match , redirect to root_url else retry
    if params[:user]["password"] != params[:user]["password_confirmation"]
      redirect_to "/login/forgot/"+params[:email]+"/"+params[:token] , :notice => "Passwords don't match, please try again"
    elsif params[:user]["password"].length >20 || params[:user]["password"].length < 5
    redirect_to "/login/forgot/"+params[:email]+"/"+params[:token] , :notice => "Password must be between 5 and 20 characters"
    elsif !(@user = User.find_by_email(params[:email])).nil? && Digest::SHA1.hexdigest(@user.auth_tokens.last.token) == params[:token]
      @user.password = Password::update(params[:user]["password"])
      @user.save
      @user.auth_tokens.destroy_all
      params[:user]["email"] = params[:email]
      user_login
      else
      redirect_to "/login/forgot/"+params[:email]+"/"+params[:token] , :notice => "Something went wrong"
    end

  end

  def select_fb_vanity
    begin
      ValidationHelper.vanity_url_checker params[:user]["vanity_url"]
      @user.vanity_url = params[:user]["vanity_url"]
    rescue
      @user.vanity_url = generate_vanity_url @user.first_name, @user.last_name
    end
    @user.save
    if @origin_url == "/"
      redirect_to @user.permalink
      return
    else
      redirect_to @origin_url
      return
    end
  end


  def register_get

    if !@user.nil? && @user.vanity_url.nil?
      @user.vanity_url = generate_vanity_url @user.first_name, @user.last_name
      @user.save
    end
    if !@user.nil?
      redirect_to @user.fullpermalink(:preferred)
      return
    end
    @fb_connect_controller =  root_url + "login/fb_login/email"
    @ga_page_category = "register"
    @user = User.new
    @user.preferred_locale = I18n.locale
    @user_email = nil ## stupid hack koz setting a bad email raises a fuckign exception
    @user_vanity_url = nil
    render :template => 'home/register_3.html.erb', :layout => false
    return
  end

  def register_post
    begin
      @user = User.new
      begin
        @user.email = params[:user]["email"].downcase.gsub(/^\ */,"").gsub(/\ *$/,"")
        raise DBArgumentError.new "Already taken" unless User.find_by_email(@user.email).nil?
        @user.contact_email = @user.email
        @user_email = nil ## hideous hack to know if the email is ok or not and to keep it along the way if it is not
      rescue
        ## stupid hack koz setting a bad email raises a fuckign exception
        @user.email = "noemail@diveboard.com"
        @user.contact_email = "noemail@diveboard.com"
        @user_email = params[:user]["email"].downcase.gsub(/^\ */,"").gsub(/\ *$/,"")
        @user_email_error = $!.message
      end

      begin
        @user.vanity_url = params[:user]["vanity_url"].downcase.gsub(" ","")
        raise DBArgumentError.new "Already taken" unless User.find_by_vanity_url(@user.vanity_url).nil?
        @user_vanity_url = nil ## hideous hack to know if the vanity is ok or not and to keep it along the way if it is not
      rescue
        ## stupid hack koz setting a bad vanity a fuckign exception
        @user_vanity_url = params[:user]["vanity_url"].downcase.gsub(" ","")
        @user_vanity_url_error = $!.message
      end

      @user.nickname = params[:user]["nickname"].capitalize
      @user.password = params[:user]["password"]
      @user.password_confirmation = params[:user]["password_confirmation"]
      @user.location = "blank"
      @user.preferred_locale = I18n.locale

      logger.debug "fullpath is "+request.host

      if !DISABLE_CAPTCHA && !verify_recaptcha
        #we check capthca only on prod
        flash[:notice] = "You may not be human, try the captcha again !"
      elsif !@user_email.nil?
        @user.errors.add(:email, "bad email")
        flash[:notice] = "Wrong email: " + @user_email_error
      elsif !@user_vanity_url.nil?
        @user.errors.add(:vanity_url, @user_vanity_url_error)
        flash[:notice] = "Wrong Diveboard URL: "+ @user_vanity_url_error
      elsif params[:user]["password"].length < 5 || params[:user]["password"].length > 20
        @user.errors.add(:password, "bad password")
        flash[:notice] = "The password must be between 5 and 20 characters"
      elsif !params[:user]["password"].match(/\ /).nil?
        @user.errors.add(:password, "bad password")
        flash[:notice] = "No spaces allowed in password"
      elsif params[:user]["password"] != params[:user]["password_confirmation"]
        @user.errors.add(:password, "bad password")
        @user.errors.add(:password_confirmation, "bad password")
        flash[:notice] = "Passwords don't match"
      elsif params[:user]["nickname"].length > 30 || params[:user]["nickname"].length < 3
        @user.errors.add(:nickname, "bad nickname")
        flash[:notice] = "Nickname must be between 3 and 30 characters"
      else
        @user.password = Password::update(params[:user]["password"])
        @user.password_confirmation = @user.password

        @user.save!
        @user.accept_newsletter_email = !params["token"].match(/true/i).nil? ## needs done AFTER user exists or association can't be done
        @user.save!
        user_login ## this will login the user properly
        PasswordReset.registration_ok(@user).deliver ## send him hellp email
        session[:ga_track_events].push :category => 'account', :action => 'register', :label => 'email'
        return
      end
    rescue
      flash[:notice] = "Could not create account :" +$!.message
    end
    @ga_page_category = "register"
    if !params[:r].blank? then
      redirect_to root_url+params[:r]
      return
    else
      render "home/register_3", :layout => false
      return
    end
  end


  def fb_login
    # this is the controller starting the connection with Facebook
    #makes the redirect to the FB OAuth
    #TODO if already has a valid Token, no need to oauth
    # params[:perms] publish_stream,email,offline_access,publish_checkins,user_photos,user_videos

    ##logger.debug "FB COOKIE contains: "+ @oauth.get_user_info_from_cookies(cookies).to_s
    ##logger.debug "FB COOKIE USER contains: "+ @oauth.get_user_from_cookies(cookies).to_s


      init_logged_user
      #check if user already exists

      if @user.nil?
        session[TOKEN] = nil
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        session[:private] = false
        logger.debug "No user here, we'll head for authentication"
        @redirect_url = @oauth.url_for_oauth_code(:permissions => params[:perms])
        if params[:js]=="1" then
          render layout: nil
        else
          redirect_to @redirect_url
        end
      else
        if @user.fb_id.nil?
          logger.debug " We know the user, he's not a FB user, he's probabling askign for a merge"
          logger.debug "in login#new session token is nil"
          @redirect_url = @oauth.url_for_oauth_code(:permissions => params[:perms])
          if params[:js]==1 then
            render layout: nil
          else
            redirect_to @redirect_url
          end
        elsif !@user.fb_permissions_granted(params[:perms])
          logger.debug " We know the user but we need more permissions"
          @redirect_url = @oauth.url_for_oauth_code(:permissions => params[:perms])
          if params[:js]==1 then
            render layout: nil
          else
            redirect_to @redirect_url
          end
        else
          logger.debug "We already know the user . no point in reauthenticating!"
          if @origin_url == "/"
            @redirect_url = "/#{@user.vanity_url}"
            if params[:js]==1 then
              render layout: nil
            else
              redirect_to @redirect_url
            end
          else
            @redirect_url = @origin_url
            if params[:js]==1 then
              render layout: nil
            else
              redirect_to @redirect_url
            end
          end
        end
      end
  end

  def fb_no


  end


  def callback
    logger.debug "Processing Callback"
    if params[:code].nil? && params[:error] == "access_denied"
      ## User probably said no to allow...
      render 'fb_no' , :layout => false
      return
    else
      begin
        logger.debug "Getting token with #{FB_APP_ID} #{FB_APP_SECRET}"
        if !params[:fb_token].blank?
          @fb_token = params[:fb_token]
        elsif !params[:code].blank?
          @fb_token = @oauth.get_access_token(params[:code])
        end
        raise DBArgumentError.new "No FB Token available" if @fb_token.nil?

        @graph = Koala::Facebook::API.new(@fb_token)
        profile = @graph.get_object("me")
        logger.debug "User profile number is #{profile["id"]}"
        @fb_id = profile["id"].to_i
        @fb_user = User.find_by_fb_id(@fb_id)
        raise DBArgumentError.new "No user data from Facebook" if @fb_id.nil?
        if !@fb_user.nil?
          @user = @fb_user
        end

        if !(authtoken = AuthTokens.find_by_token(params[:auth_token])).nil? || ( !session[TOKEN].nil? &&  !(authtoken = AuthTokens.find_by_token(session[TOKEN])).nil?  && authtoken.expires > Time.now) || ( !cookies.signed[TOKEN].nil? && !(authtoken = AuthTokens.find_by_token(cookies.signed[TOKEN])).nil? && authtoken.expires > Time.now)
          @cookie_user = authtoken.user
          logger.info " User already authentified and exists, id = #{@user.id}, vanity = #{@user.vanity_url || ""}"
        end

        if @user.nil?
          begin
            register_fb_user_from_token @fb_token
            @user.source = session[:utm_campaign]
            @user.save
          rescue
            flash[:notice] = "Could not create your account, please contact support@diveboard.com"
          end
        else
          @user.fbtoken = @fb_token
          @user.save
        end

        if @user.vanity_url.nil?
          ##extra checks
          @user = generate_vanity_url @user.first_name, @user.last_name
          @user.save
        end


        Rails.logger.debug "We've got user #{@user.id} ready"

        authtoken = AuthTokens.create(:user_id => @user.id, :expires => 1.year.from_now)
        logger.debug "Setting up a new token for #{@user.id}"
        session[TOKEN] = authtoken.update_token
        session[:private] = true
        cookies.delete TOKEN, domain: COOKIES_DOMAIN
        cookies.signed[TOKEN] = {:value  => session[TOKEN],  :expires => authtoken.expires, domain: COOKIES_DOMAIN}
        logger.debug "User found succesfully - moving on"
        
        if@origin_url.blank? || @origin_url == "/"
          redirect_url = URI.parse @user.fullpermalink(:preferred)
        else
          redirect_url = URI.parse  @origin_url
        end

        redirect_args = URI.decode_www_form redirect_url.query || [] rescue []
        params.each do |k,v|
          redirect_args.push [k,v] if k.match /^utm_/
        end
        redirect_url.query = URI.encode_www_form redirect_args unless redirect_args.empty?
        redirect_to redirect_url.to_s
        return
      rescue
        #Something went wrong - let's do that again
        Rails.logger.debug "FB LOGIN FAILED #{$!.message}"
        Rails.logger.debug "#{$!.backtrace}"
        fb_login
        return
      end
    end
  end

  def delete
    #this will drop the session
    session[TOKEN]=nil
    cookies.delete TOKEN, domain: COOKIES_DOMAIN
    cookies.delete :sudo, domain: COOKIES_DOMAIN
    session[:baskets]=nil
    redirect_to params[:r].gsub(/.*\/\/+/,'/') and return if !params[:r].blank?
    redirect_to "/"
  end

    def deleteV2
    #this will drop the session
    session[TOKEN]=nil
    cookies.delete TOKEN, domain: COOKIES_DOMAIN
    cookies.delete :sudo, domain: COOKIES_DOMAIN

    render :nothing => true, :status => 200
  end

  def update_fbtoken
    begin
      raise DBArgumentError.new "No logged user" if @user.nil?
      raise DBArgumentError.new "No FB token" if params[:fbtoken].blank?
      raise DBArgumentError.new "No FB user id" if params[:fbuserid].blank?
      begin
        params[:fbuserid].to_i
      rescue
        raise DBArgumentError.new "Invalid FB user id"
      end
      user_check = User.find_by_fb_id(params[:fbuserid].to_i)
      if !user_check.nil? && user_check.id != @user.id
        raise DBArgumentError.new "FB user id already taken", user_id: params[:fbuserid]
      end
      user_check = User.find_by_fbtoken(params[:fbtoken])
      if !user_check.nil? && user_check.id != @user.id
        raise DBArgumentError.new "FB token already taken for user_id", token: params[:fbtoken], user_id: params[:fbuserid]
      end
      @user.fbtoken = params[:fbtoken]

      @user.fb_id = params[:fbuserid].to_i
      @user.save
      @user.update_fb_permissions
      render :json => {:success => true}
    rescue
      render :json => {:success => false, :error => $!.message}
      logger.debug $!.message
      #logger.debug $!.stacktrace
    end
  end

  private
  def init_oauth
    callback_url = root_url + "login/callback"
    args = {}
    params.each do |k,v|
      args[k] = v if k.match /^utm_/
    end
    callback_url += "?#{args.to_query}" unless args.empty?
    @oauth = Koala::Facebook::OAuth.new(FB_APP_ID, FB_APP_SECRET, callback_url) #init oauth
    @app_secret = FB_APP_SECRET
  end

end
