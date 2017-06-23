class HomeController < ApplicationController
  #define the proper layout
  layout 'index'
  before_filter :init_logged_user, :save_origin_url, :signup_popup_hidden, :except => [:nouserpic] #init the graph connection and everyhting user related
  #include ActionView::Helpers::SanitizeHelper

  def index
    @pagename = "HOME"
    @ga_custom_url = "/"
    @ga_page_category = "home"

    if !@user.nil? && !params[:redirect] then
      if @I18n_requested then
        redirect_to @user.fullpermalink(@I18n_requested)
      else
        redirect_to @user.fullpermalink(:preferred)
      end
      return

    end

    #just show the link to facebook connect button
    @fb_connect_controller =  root_url + "login/fb_login/email"
    render :template => 'home/index_4.html.erb', :layout => false

  end

  def stats
    divesnb = ActiveRecord::Base.connection.select_value('select count(*) from dives')
    spotsnb = ActiveRecord::Base.connection.select_value('select count(*) from spots')
    fishesnb = ActiveRecord::Base.connection.select_value('select count(*) from eolcnames') + ActiveRecord::Base.connection.select_value('select count(*) from eolsnames')
    diversnb = ActiveRecord::Base.connection.select_value('select count(*) from users')
    picsnb = ActiveRecord::Base.connection.select_value('select count(*) from pictures')

    render :json => {:divers => diversnb.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,'),
                     :dives => divesnb.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,'),
                     :spots => spotsnb.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,'),
                     :fish => fishesnb.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,'),
                     :pics => picsnb.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')}
  end

  def search
    query = params[:q] ## we get the question
    fish = []
    fish << Eolsname.search(query)
    fish << Eolcname.search(query)
    fishnb = fish[0].count + fish[1].count
    user = User.search(query)
    usernb = user.count
    spot = Spot.search query, :with =>{:id => 2..Spot.last.id, :moderate_id => 'NULL'}
    spotnb = spot.count

    answer = Hash.new()
    answer["fish"] = []
    answer["user"] = []
    answer["spot"] = []
    answer["stats"] = {"fish"=>fishnb, "user" => usernb, "spot"=> spotnb}
    ## send {name => , link =>}
    i = 0
    begin
      if fish[1][i].nil?
        answer["fish"] << {"name"=>"", "link" => ""}
      else
        answer["fish"] << {"name"=>fish[1][i].cname, "link" => ""} ##link is TBD !!!
      end
      if spot[i].nil?
        answer["spot"] << {"name"=>"", "link" => ""}
      else
        answer["spot"] << {"name"=>"#{spot[i].name}, #{spot[i].location}, #{spot[i].country.cname}", "link" => ""} ##link is TBD !!!
      end
      if user[i].nil?
        answer["user"] << {"name"=>"", "link" => ""}
      else
        answer["user"] << {"name"=>user[i].nickname, "link" => "/#{user[i].vanity_url}"} ##link is TBD !!!
      end

      i += 1
    end while i<3

    render :json => answer

  end

  def sitemap
    require 'open-uri'
    ##http://www.google.com/support/webmasters/bin/answer.py?answer=71453 >> todo when we have too many urls
    #get blog sitemap
    render :template => 'home/sitemap.xml.erb'
  end


  def register
    ## register page - our last attempt to kindly as the user to fb login :)
    if !@user.nil? && @user.vanity_url.nil?
      @user = generate_vanity_url @user.first_name, @user.last_name
      @user.save
    end

    if !@user.nil?
      redirect_to @user.fullpermalink(:preferred)
      return
    end

    @ga_page_category = "register"

    @fb_connect_controller =  root_url + "login/fb_login/email"
    @user = User.new
    @user.preferred_locale = I18n.locale
    render :template => 'home/register_3.html.erb', :layout => false
    return
  end

  def fb_vanity
    #this is to ask the new FBuser to choose a vanity url
    if @user.nil?
      render :layout => 'layouts/main_layout.html.erb', :template => 'layouts/404.html.erb'
      return
    end
    if !@user.vanity_url.nil?
      redirect_to @user.fullpermalink(:preferred)
      return
    end


    logger.debug "user may be new, asking for vanity url"
    @vanity_url = generate_vanity_url(@user.first_name, @user.last_name)

    @ga_page_category = "register fb_vanity"
    render :template => 'home/fb_vanity.html.erb', :layout => false
    return
  end

  def pwd_reset
    if !(@user = User.find_by_email(params[:email])).nil? && begin Digest::SHA1.hexdigest(@user.auth_tokens.last.token).to_s == params[:token] rescue false end
      #this sounds legit
      @result = nil
      @email = params[:email]
      @token = params[:token]
      params[:help] = "pwdreset"

      @ga_page_category = "password reset"
      render :template => 'home/register_3.html.erb', :layout => false
      return
    else
      redirect_to "/login/forgot", :notice => "Sorry the link you provided is not legit. Maybe you managed to login since its generation. Please generate a new link"
      return
    end

  end

  def forgot
    ## forgot my pwd page - our last attempt to kindly as the user to fb login :)
    @fb_connect_controller =  root_url + "login/fb_login/email"
    @ga_page_category = "password reset"
    @result = nil
    params[:help] = "pwd"
    ##if we get an email submitted we need to send out da mail if user exists
    if !DISABLE_CAPTCHA && !verify_recaptcha
      #we check capthca only on prod
      @user = User.new
      flash[:notice] = "You may not be human, try the captcha again !" unless params[:user].nil?
      render "home/register_3", :layout => false
      #redirect_to root_url+"login/register", :notice => "You may not be human, try the captcha again !"
      return
    end

    if !params[:user].nil? && !(email = params[:user]["email"].downcase).nil?
      #we've been called with the email to reset
      if (user = User.find_by_email(email)).nil?
        flash[:notice] = "No user matches that email - Maybe you used Facebook to login?"
      else
        PasswordReset.pass_reset(user).deliver
        flash[:notice] = "An email has been sent to this address to proceed to password reset"
      end
      #render "home/register_3", :layout => false
      redirect_to "/login/register?help="+params[:help], :flash =>{:notice => flash[:notice]}
      return
    else
      ##I guess that's a 404, you shouldn't be here anyway...
      render 'layouts/404', :layout => false
      return
    end
  end

  def forgot_email
    ## forgot my pwd page - our last attempt to kindly as the user to fb login :)
    @fb_connect_controller =  root_url + "login/fb_login/email"
    @ga_page_category = "password reset"
    @result = nil
    params[:help] = "email"

    ##if we get an email submitted we need to send out da mail if user exists
    if !DISABLE_CAPTCHA && !verify_recaptcha
      #we check capthca only on prod
      @user = User.new
      flash[:notice] = "You may not be human, try the captcha again !"
      render "home/register_3", :layout => false
      #redirect_to root_url+"login/register", :notice => "You may not be human, try the captcha again !"
      return
    end
    if !params[:user].nil? && !(vanity_url = params[:user]["vanity_url"].downcase).nil?
      #we've been called with the email to reset
      if (user = User.find_by_vanity_url(vanity_url)).nil?
        redirect_to "/login/register?help=email", :notice => "No user matches that vanity url"
      else
        PasswordReset.remind_login(user).deliver
        redirect_to "/login/register?help=email", :notice => "An email has been sent to your address with your login information"
      end
    else
        ##I guess that's a 404, you shouldn't be here anyway...
        render 'layouts/404', :layout => false
        return
    end
  end

  def nouserpic
    Rails.logger.debug "image #{:image_id} is missing"
    redirect_to "/img/no_picture.png"
    return
  end

  def render_partial_header
    render :partial => 'layouts/top_menu'
  end

  def redirect_bulk
    if !params[:auth_token].blank? then
      session[:private] = true
      session[TOKEN] = params[:auth_token]
    end

    if !@user.nil? then
      if @I18n_requested then
        redirect_to @user.fullpermalink(@I18n_requested) + "/bulk?" + request.query_parameters.except(:auth_token).to_query
      else
        redirect_to @user.fullpermalink(:preferred) + "/bulk?" + request.query_parameters.except(:auth_token).to_query
      end
    else
      index
    end
  end


end
