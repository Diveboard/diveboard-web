## Read and updates a user settings


class SettingsController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  layout 'main_layout'



  def read
    @pagename = "SETTINGS"
    @ga_page_category = 'settings'
    ## prints out the web form
    if session[:private]
      ## there is a point in being here
      @fb_post_perms = @user.fb_permissions_granted("publish_stream")
      if params[:id].nil?
        @menu_id = 1
      else
        @menu_id = params[:id].to_i
      end

      @menu_id = 4 if @user.is_group? && ![2,4].include?(@menu_id)

    else
      ##there's no point in being here...
      redirect_to "/login/register", :notice => "You need to login to access the settings page"
      return
      #render :layout => 'main_layout', :template => 'layouts/404'
    end

  end

  def orders
    @pagename = "ORDERS"
    @ga_page_category = 'orders'
    ## prints out the web form
    if session[:private]
      ## there is a point in being here

      if !params[:basket_id].blank? then
        @basket = Basket.decode_reference(params[:basket_id]) rescue nil
        @basket = nil if @basket && !@basket.is_private_for?(:caller => @user)
      end
      if !params[:message_id].blank? then
        @message = InternalMessage.fromshake params[:message_id] rescue nil
        @message = nil if @message && !@message.is_private_for?(:caller => @user)

        if @message && @message.status == 'new' then
          @message.status = 'read'
          @message.save
        end
        if @message.in_reply_to.is_a? Basket then
          @basket ||= @message.in_reply_to
        end
      end

      if @basket then
        @menu_id = 3
      elsif @message then
        @menu_id = 4
      elsif params[:id]==3 || params[:id]==4
        @menu_id = params[:id]
      else
        @menu_id = 3
      end

    else
      ##there's no point in being here...
      redirect_to "/login/register", :notice => "You need to login to access the settings page"
      return
      #render :layout => 'main_layout', :template => 'layouts/404'
    end

  end


  def update
  begin
    ## ajax update of the data
    #vanity: $("#username").val(),
    #nickname: $("#nickname").val(),
    #location: $("#country").attr("shortname"),
    #gender: $("#gender").val(),
    #birthday:$("#birthday").val()
    #id: <%=@user.id%>

    begin
      u = @user ### the fuck was that !?!? we know who user is !!! =>  User.find(params[:id])
    rescue
      render :json => {:success => false, :reason => "Unknown user"}
      return
    end
    ##  *********MENU 1******
    if  params[:current_menu] == "1"
      begin
        logger.debug "Updating menu 1"
        save_origin_url "/settings/1"

        if !params[:email].empty? && (params[:email].match(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/).nil? || params[:email].length>254)
          logger.debug "contact email is not properly formatted"
          render :json => {:success => false, :message => "Email is not properly formatted", :email => false }
          return
        end

        if u.fbtoken != params[:fbtoken] && !params[:fbtoken].empty?
          ## we need to merge just in case
          merge_fb_user(params[:fbtoken])
        end

        if params[:currency].blank?
          u.currency = nil
        else
          u.currency = params[:currency]
        end

        u.settings = params[:settings]
        u.contact_email = params[:email]
        u.preferred_locale = params[:preferred_locale]
        u.accept_weekly_notif_email = !params[:weekly_notif_email].match(/true/).nil?
        u.accept_instant_notif_email = !params[:instant_notif_email].match(/true/).nil?
        u.accept_weekly_digest_email = !params[:weekly_digest_email].match(/true/).nil?
        u.accept_newsletter_email = !params[:newsletter_email].match(/true/).nil?

        u.save!

        render :json => {:success => true}
      rescue
        logger.debug "Exception caught in settings conctroller, menu 4 : (#{$!})"
        render :json => {:success => false, :message => "Exception caught (#{$!})"}
      end

    ##  *********MENU 2******
    elsif  params[:current_menu] == "2"
      save_origin_url "/settings/2"
      raise DBArgumentError.new "Missing vanity url" if params[:vanity].blank?
      if params[:vanity].downcase != u.vanity_url.downcase then ValidationHelper.vanity_url_checker(params[:vanity]) end
      ## vanity url is really OK
      logger.debug "Vanity URL is OK to change"
      @user.vanity_url = params[:vanity].downcase
      @user.save


      ## we update user's permissions in case they've been changed
      u.update_fb_permissions

      ##let's check if any auth things have changed
      if @user.email.nil? && params[:email].blank?
        ##no pwd and no pwd to set
        render :json => {:success => true}
        return
      elsif !@user.email.nil? && @user.email.downcase == params[:email].downcase && params[:new_pwd].empty?
        ##pwd but no change
        render :json => {:success => true}
        return
      end




      ##first, we need to check current password
      if (!@user.email.nil?  && !Password::check(params[:old_pwd],@user.password))
        render :json => {:success => false, :password => false}
        return
      else
        ##time to update email and password if not null
        ##check that login email is available and well formated
        if params[:email].match(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/).nil? || params[:email].length>254
          render :json => {:success => false, :message => "Email is not properly formatted", :email => false }
          return
        end

        u_test = User.find_by_email(params[:email])
        if u_test.nil? || u_test.id == u.id
          u.email = params[:email]
        else
          render :json => {:success => false, :message => "New email login is taken", :email => false }
          return
        end
        new_pwd = params[:new_pwd]

        if new_pwd == ""
          u.save
          render :json => {:success => true}
          return
        end

        if new_pwd.length > 4 && new_pwd.length < 21 && new_pwd.match(/\ /).nil?
          ##new_pwd seems ok
          u.password = Password::update(new_pwd)
          u.save
          render :json => {:success => true}
          return
        else
          ##new_pwd is bogus
          render :json => {:success => false, :message => "New password is not ok" }
        end
      end
      ##pwd is ok, let's move on
    else
      render :json => {:success => false, :message => "Wrong menu call" }
    end
  rescue
    render :json => {:success => false, :message => $!.message }
  end
  end

  def check_vanity_url
    begin
      ##remove all spaces
      vanity = params[:vanity].downcase.gsub(" ","")
      ValidationHelper.vanity_url_checker vanity
      raise DBArgumentError.new "vanity url is taken" unless User.find_by_vanity_url(vanity).nil?
      render :json => {:success => true, :available => true}
      return
    rescue
      render :json => {:success => true, :available => false, :error => $!.message}
      return
    end
  end

  def check_email
  begin
    if !params[:email].nil?
      ##remove trailing spaces
      email = params[:email].downcase.gsub(/^\ */,"").gsub(/\ *$/,"")
      begin
        ValidationHelper.check_email_format(email)
      rescue
        render :json => {:success => false}
        return
      end
      if  User.find_by_email(email).nil?
        render :json => {:success => true, :available => true}
        return
      else
        render :json => {:success => true, :available => false}
        return
      end
    else
      render :text => "illicit use of the API"
    end
  rescue
    render api_exception $!
  end
  end

  def uploadpict
    begin
      logger.debug "1"
      user = params[:user_id]
      logger.debug "2"
      ajax_upload = params[:qqfile].is_a?(String)
      logger.debug "3 AJAX_UPLOAD IS "+ajax_upload.to_s
      filename = ajax_upload  ? params[:qqfile] : params[:qqfile].original_filename
      logger.debug "4"
      extension = filename.split('.').last
      logger.debug "5"
      logger.debug "uploaded "+filename+" with extension "+extension

      if %w(jpg jpeg png gif tiff tif bmp tga xcf psd ai svg pcx pdf).include?(extension.downcase)
        # Creating a temp file
        filename = user+"-"+Time.now.strftime("%Y%m%d%H%M%S")+"."+extension
        tmp_file = File.new("public/tmp_upload/"+filename,"wb")
        logger.debug "6"
        if ajax_upload then
          logger.debug "it's an AJAX Upload"
          tmp_file.write  request.body.read
          logger.debug "7"
        else
          logger.debug "it's NOT an AJAX Upload"
          tmp_file.write params[:qqfile].read
          logger.debug "8"
        end
        # Now reading from the file
        #TODO check the file, read the # of dives and render them back
        tmp_file.close
        logger.debug "render success for uploaded image: "+filename

        cropable = %w(jpg jpeg png gif).include?(extension.downcase)
        render :json => {:success => true, :filename => filename, :tempfullpermalink => "#{ROOT_URL}tmp_upload/"+filename, :cropable => cropable}, :content_type => "text/html"
      else
        render :json => {:success => false , :failure => "can't recognize file extension"}, :content_type => "text/html"
      end
    rescue
      render :json => {:success => false , :failure => $! }, :content_type => "text/html"
    end
  end



end
