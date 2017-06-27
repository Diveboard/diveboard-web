class NotifyShop < ActionMailer::Base
  default :from => "Diveboard <no-reply@diveboard.com>",
    :content_type => "html"

  add_template_helper(ApplicationHelper)

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


  def notify_daily_action(shop)
        return false unless shop.status == :public
        @recipient = shop
        @shop = @recipient
        @user = @recipient.user_proxy
        @global_inbox = @user.global_inbox
        @tag = "notify_daily_action"

        actions = 0
        @global_inbox.each {|e|
          e[:count].map do |what, nb|
            actions += nb
          end
        }
        @subtitle = "#{actions} new item#{"s" if actions>0} in your Diveboard inbox"
        send_from_sendgrid
        if shop.is_claimed?
          to = shop.owners.map(&:contact_email).reject {|e| e.nil? || e == ""}
        else
          to = shop.email
        end

        text = render_to_string 'notify_shop/notify_daily_action.text', :layout => false
        html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_shop/notify_daily_action.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

        mail :to => to,
          #:bcc => Rails.application.config.mailer_baskets_bcc,
          :subject => @subtitle do |format|
          format.text{ render :text => text }
          format.html{ render :text => html }
    end
  end


  def notify_claim(shop, claimer, source=nil)
    @shop = shop
    @recipient = @shop
    @claimer = claimer
    @tag = "notify_claim"

    @validation_url = ShopClaimHelper.generate_url_confirm_claim(claimer, shop.user_proxy, source)
    logger.info "Notification mail to #{@shop.email} for claim on #{@shop.name} (#{@shop.id}) by #{@claimer.nickname} (#{@claimer.id})"
    logger.debug "URL for validation : #{@validation_url}"
    send_from_sendgrid
    mail( { :to => @shop.email, :subject => "Authorization request to edit your Diveboard page"} )
  end

  def notify_buy(shop, buyer, message, subject)
    @shop = shop
    @recipient = @shop
    @buyer = buyer
    @message = message
    @tag = "notify_buy"


    send_from_sendgrid
    mail( { :to => @shop.email, :subject => "User want to " + subject} )
  end

    def notify_command(shop, buyer,basket, message, subject)
      @shop = shop
      @recipient = @shop
      @basket=basket
      @buyer = buyer
      @message = message
      @tag = "notify_buy"

      html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_shop/notify_command.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe


      reply_address = buyer.contact_email || buyer.email || "support@diveboard.com" rescue "support@diveboard.com" 

      send_from_sendgrid
      mail :to => @shop.email, 
        :bcc => Rails.application.config.mailer_baskets_bcc,
        :reply_to => reply_address,
        :subject => "Booking request" do |format|
        format.html{ render :text => html }
      end

  end

  def notify_basket_status user, basket
    @recipient = user
    @basket = basket
    @user = basket.user
    @shop = basket.shop
    @subtitle = ""
    @tag = "notify_basket_status"

    text = render_to_string 'notify_shop/notify_basket_status.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_shop/notify_basket_status.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    Rails.logger.debug "notify_basket_status: ===================================================="
    Rails.logger.debug "notify_basket_status: "+(caller.join "\nnotify_basket_status: ")

    send_from_sendgrid
    mail :to => @recipient.contact_email,
      :bcc => Rails.application.config.mailer_baskets_bcc,
      :subject => "Status changed for your order #{@basket.reference}" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end
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
