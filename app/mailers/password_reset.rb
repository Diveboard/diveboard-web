require 'digest/sha2'

class PasswordReset < ActionMailer::Base
  default :from => "password-reset@diveboard.com",
  :content_type => "text/html"

  # Call add_sendgrid_headers after generating each mail.
  def initialize(method_name=nil, *args)
    self.class.delivery_method = :smtp
    self.class.smtp_settings = {
      :user_name => "apikey",
      :password => SENDGRID_API,
      :domain => "diveboard.com",
      :address => "smtp.sendgrid.net",
      :port => 587,
      :authentication => :plain,
      :enable_starttls_auto => true
    }

    super.tap do
      add_sendgrid_headers(method_name, args) if method_name
    end
  end

  def pass_reset user
    @user = user
    authtoken = AuthTokens.create(:user_id => @user.id, :expires => 1.day.from_now)
    authtoken.update_token
    @reset_url = HtmlHelper.find_root_for(@user.preferred_locale)+"login/forgot/"+@user.email+"/"+Digest::SHA1.hexdigest(authtoken.token).to_s
    mail(:to => @user.contact_email, :subject => "Diveboard password reset")
  end

  def registration_ok user
    @user = user
    @logbook_url = @user.preferred_root_url+@user.vanity_url rescue ROOT_URL
    mail(:to => @user.contact_email, :subject => "Welcome to Diveboard", :from => "team@diveboard.com")
  end

  def remind_login user
    @user = user
    mail(:to => @user.contact_email, :subject => "Diveboard login reminder")
  end


end
