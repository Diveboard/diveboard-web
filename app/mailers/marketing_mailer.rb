## Mailer for all marketing emails activation / reactivation...
class MarketingMailer < ActionMailer::Base
   default :from => "Diveboard <no-reply@diveboard.com>",
    :content_type => "text/html"

  add_template_helper(ApplicationHelper)

   # Call add_sendgrid_headers after generating each mail.
  def initialize(method_name=nil, *args)
    Rails.logger.debug "Sending from sendgrid"
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


  ##### [SHOP]
  ##### [ONBOARDING]
  #####  Step 1
  #####  tag : marketing_shop_onboarding_check_info
  def shop_check_info(shop)
    #This is step 1 of shop onboarding : ask them to chekc out their details
    #To be sent week+1 after shop has been created on the platform
    return false if shop.nil?
    return false if shop.class.to_s != "Shop"

    @tag = "marketing_shop_onboarding-check_info"


    Rails.logger.debug "Sending #{@tag} to shop #{shop.id}"
    send_from_sendgrid
    ##This is only sent to shops NOT claimed
    if shop.is_claimed?
      Rails.logger.debug "Shop is already claimed - not sending the email"
      return false
    end

    if !EmailMarketing.where(:target_id => shop.id).where(:target_type => shop.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end

    @recipient = shop
    @shop = @recipient
    @user = @recipient.user_proxy
    @subtitle = "Please confirm your free listing data"
    to = shop.email
    @to = to

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])

    begin
      user_id = "*"
      salt = rand(100000)
      group = @shop.user_proxy
      sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
      @claim = (group.fullpermalink(:canonical)+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
    rescue
      @claim = ""
    end

    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/shop_check_info.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    mail :to => to,
      :subject => @subtitle do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => shop.id,
      :target_type => shop.class.to_s,
      :recipient_id => shop.id,
      :recipient_type => shop.class.to_s,
      :email => to,
      :content => @tag
    )

    return true

  end



   ##### [SHOP]
  ##### [ONBOARDING]
  #####  Step 1-bis
  #####  tag : marketing_shop_onboarding_claim_page
  def shop_claim_page(shop)
    #This is step 1 of shop onboarding : ask them to chekc out their details
    #To be sent week+1 after shop has been created on the platform
    return false if shop.nil?
    return false if shop.class.to_s != "Shop"

    @tag = "marketing_shop_onboarding_claim_page"


    Rails.logger.debug "Sending #{@tag} to shop #{shop.id}"
    send_from_sendgrid
    ##This is only sent to shops NOT claimed
    if shop.is_claimed?
      Rails.logger.debug "Shop is already claimed - not sending the email"
      return false
    end

#    if !EmailMarketing.where(:target_id => shop.id).where(:target_type => shop.class.to_s).where(:content => @tag).empty?
#      Rails.logger.debug "Email already sent - NOT RESENDING"
#      return false
#    end

    @recipient = shop
    @shop = @recipient
    @user = @recipient.user_proxy
    @subtitle = "Time to pimp up your listing"
    to = shop.email
    @to = to

    ## check if email is opt out
    return false unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])

    begin
      user_id = "*"
      salt = rand(100000)
      group = @shop.user_proxy
      sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
      @claim = (group.fullpermalink(:canonical)+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
    rescue
      @claim = ""
    end
    

    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/shop_claim_page.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    Rails.logger.debug html

    mail :to => to,
      :subject => @subtitle do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => shop.id,
      :target_type => shop.class.to_s,
      :recipient_id => shop.id,
      :recipient_type => shop.class.to_s,
      :email => to,
      :content => @tag
    )

    return true

  end

  ##### [SHOP]
  ##### [ONBOARDING]
  #####  Step 2 - Ask a shop to asks their fans to leave reviews
  #####  tag : marketing_shop_onboarding_ask_fb_reviews
  def shop_ask_fb_reviews(shop)


    return false if shop.nil?
    return false if shop.class.to_s != "Shop"

    @tag = "marketing_shop_onboarding-ask_fb_reviews"


    Rails.logger.debug "Sending #{@tag} to shop #{shop.id}"
    send_from_sendgrid

    if !EmailMarketing.where(:target_id => shop.id).where(:target_type => shop.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end

    @recipient = shop
    @shop = @recipient
    @user = @recipient.user_proxy
    @subtitle = "Make your fans vouch for you!"
    to = shop.email
    @to = to

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])

    begin
      user_id = "*"
      salt = rand(100000)
      group = @shop.user_proxy
      sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
      @claim = (group.fullpermalink+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
    rescue
      @claim = ""
    end

    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/shop_ask_fb_reviews.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    mail :to => to,
      :subject => @subtitle do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => shop.id,
      :target_type => shop.class.to_s,
      :recipient_id => shop.id,
      :recipient_type => shop.class.to_s,
      :email => to,
      :content => @tag
    )

    return true


  end

  ##### [SHOP]
  ##### [ONBOARDING]
  #####  Step 3 - Ask a shop to sell online
  #####  tag : marketing_shop_onboarding_online_bookings
  def shop_online_bookings(shop)

    return false if shop.nil?
    return false if shop.class.to_s != "Shop"

    @tag = "marketing_shop_onboarding-online_bookings"


    Rails.logger.debug "Sending #{@tag} to shop #{shop.id}"
    send_from_sendgrid

    if !EmailMarketing.where(:target_id => shop.id).where(:target_type => shop.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end

    @recipient = shop
    @shop = @recipient
    @user = @recipient.user_proxy
    @subtitle = "Start accepting online bookings for free"
    to = shop.email
    @to = to

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])

    if !@shop.paypal_id.nil? 
      Rails.logger.debug "Shop already paypal linked"
      return
    end

    begin
      user_id = "*"
      salt = rand(100000)
      group = @shop.user_proxy
      sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
      @claim = (group.fullpermalink+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
    rescue
      @claim = ""
    end

    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/shop_market_online_booking.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    mail :to => to,
      :subject => @subtitle do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => shop.id,
      :target_type => shop.class.to_s,
      :recipient_id => shop.id,
      :recipient_type => shop.class.to_s,
      :email => to,
      :content => @tag
    )

    return true
  end


  def external_user_join(e_user)
    @tag = "marketing_external_user_transform-join"
    @recipient = e_user
    to = @recipient.email

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])


    if !EmailMarketing.where(:target_id => @recipient.id).where(:target_type => @recipient.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end

    Rails.logger.debug "ExternalUser recipient #{@recipient.id} #{@recipient.nickname}"
    begin
      @buddy = @recipient.users_buddies.first.user
      raise ArgumentError, "user buddy is nil" if @buddy.nil?
    rescue
      return
    end
    @comment_text = "Join your buddy #{@buddy.nickname } on Diveboard"
    @subtitle = @comment_text 
      
    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/external_user_join.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    mail :to => to,
      :subject => "Join your dive buddies on Diveboard" do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => @recipient.id, 
      :target_type => @recipient.class.to_s,
      :recipient_id => @recipient.id,
      :recipient_type => @recipient.class.to_s,
      :email => to,
      :content => @tag
    )

    return true



  end


  def user_reffer_friends(user)
    # this is for users who have logged dives with us - we ask them to tell their friends !
    @tag = "marketing_internal_user-reffer_simple"
    @recipient = user
    to = user.contact_email

    @subtitle = "Share Diveboard with your scuba friends"


     ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])

    ## we need users with at least 2 dives
    return unless @recipient.dives.count > 1


    if !EmailMarketing.where(:target_id => @recipient.id).where(:target_type => @recipient.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end



    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/user_reffer_simple.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe


    mail :to => to,
      :subject => "Share Diveboard with your scuba friends" do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => @recipient.id, 
      :target_type => @recipient.class.to_s,
      :recipient_id => @recipient.id,
      :recipient_type => @recipient.class.to_s,
      :email => to,
      :content => @tag
    )

    return true




  end



  def request_user_emotions(user)

     # this is for users who have logged dives with us - we ask them to tell their friends !
    @tag = "marketing_internal_user-emotion_survey"
    @recipient = user
    to = user.contact_email

    @subtitle = "Support research in scuba - we need your help"


     ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag.split("-")[0])


    if !EmailMarketing.where(:target_id => @recipient.id).where(:target_type => @recipient.class.to_s).where(:content => @tag).empty?
      Rails.logger.debug "Email already sent - NOT RESENDING"
      return false
    end


    html = HtmlHelper::Inliner.new(
          (render_to_string 'onboarding/emotion_survey.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    Rails.logger.debug "html: #{html}"

    mail :to => to,
      :subject => @subtitle do |format|
        format.html{ render :text => html }
      end

    EmailMarketing.create(
      :target_id => @recipient.id, 
      :target_type => @recipient.class.to_s,
      :recipient_id => @recipient.id,
      :recipient_type => @recipient.class.to_s,
      :email => to,
      :content => @tag
    )

    return true


  end


  def send_from_sendgrid
    NotifyShop.delivery_method = :smtp
    NotifyShop.smtp_settings = {
      :user_name => "diveboard",
      :password => SENDGRID_API,
      :domain => "diveboard.com",
      :address => "smtp.sendgrid.net",
      :port => 587,
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  end



end