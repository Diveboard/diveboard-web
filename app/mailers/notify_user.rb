class NotifyUser < ActionMailer::Base
  default :from => "DiveBoard updates <no-reply@diveboard.com>",
    :content_type => "text/html"

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


  def notify_buddy_added(recipient, dive)
    @recipient= recipient
    @buddy = dive.user
    @dive = dive
    @tag = "notify_buddy_added"
    @subtitle = "Scuba memories are forever, remember this dive?"
    text = render_to_string 'notify_user/notify_buddy_added.text', :layout => false

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_buddy_added.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email, :subject => "You've been tagged on a scuba dive" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end

  end

  def share_to_friend(from, to, subject, message, shop)
    @b_from = from
    @b_to = to
    @message = message
    @tag = "share_to_friend"
    @shop = shop

    send_from_sendgrid
    mail( { :to => @b_to, :subject => subject} )
  end


  def invite_buddy(from, external_buddy)
    raise DBArgumentError.new 'Impossible to notify user without email' if external_buddy.email.blank?
    @b_from = from
    @b_to = external_buddy
    @tag = "invite_buddy"
    @recipient = @b_to
    logger.info "Invitation mail for BUDDY sent to '#{external_buddy.email}' - '#{external_buddy.nickname}' - '#{from.id}'"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(external_buddy.email, @tag)

    send_from_sendgrid
    mail( { :from => "Diveboard invitations <no-reply@diveboard.com>",
      :to => external_buddy.email,
      :subject => "#{from.nickname} would like to invite you on Diveboard"} )
  end

  def notify_print_dives user, link
    @recipient = user
    @logbook_url = link
    @subtitle = "The prawns are done building your logbook!"
    @tag = "notify_print_dives"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    text = render_to_string 'notify_user/notify_print_dives.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_print_dives.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email, :subject => "Your PDF logbook is ready for download" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end

  end

  def notify_shop_granted user, shop
    @recipient = user
    @shop = shop
    @subtitle = "You're cleared"
    @tag = "notify_shop_granted"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    text = render_to_string 'notify_user/notify_shop_granted.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_shop_granted.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email,
      #:bcc => Rails.application.config.mailer_baskets_bcc,
      :subject => "Rights granted on Diveboard for #{@shop.name}" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end
  end

  def notify_new_message message, recipient
    @recipient = recipient
    @tag = "notify_shop_granted"
    from_shop = message.from_group.shop_proxy rescue nil


    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    if !from_shop.nil? then
      @from_name = from_shop.name
      @from_pic = message.from_group.picture_small
    else
      from = message.from
      @from_name = from.nickname
      @from_pic = from.picture_small
    end

    @msg_url = message.fullpermalink :to, :locale

    @subtitle = "The mailman has something for you"
    @content = message.message
    text = render_to_string 'notify_user/notify_new_message.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_new_message.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email, :subject => message.topic do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end
  end

  def notify_basket_status user, basket
    @recipient = user
    @basket = basket
    @shop = basket.shop
    @subtitle = ""
    @tag = "notify_basket_status"


    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    text = render_to_string 'notify_user/notify_basket_status.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_basket_status.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email,
      :bcc => Rails.application.config.mailer_baskets_bcc,
      :subject => "Status changed for your order with #{@shop.name}" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end
  end


  def notify_like(owner, page, arg_data, type)
    @data = arg_data
    @page = page
    @type = type.to_s
    @tag = "instant_notif_email"

    if type == :picture
      @dive = @page.dive
    elsif type == :dive
      @dive = @page
    elsif type == :blogpost
      @post = @page
    end

    if !owner.accept_instant_notif_email? then
      logger.debug "Notification to #{owner.nickname} [#{owner.id}] has not been sent due to user preference"
      return
    end


    if owner.contact_email.nil? then
      logger.warn "Notification to #{owner.nickname} [#{owner.id}] has not been sent due to contact mail being NIL"
      return
    end

    logger.debug "Filtering the notifications with '#{NOTIFICATION_MAIL_FILTER}'"

    if owner.contact_email.match(NOTIFICATION_MAIL_FILTER).nil? then
      logger.warn "Notification to #{owner.nickname} [#{owner.id}] @ [#{owner.contact_email}] has not been sent due to FILTERING"
      return
    end


    #TODO: check the user settings !!!

    if @data.nil? || (!@data.nil? && @data["count_likes"] != false)
      # Fetches some information on the shared page
      base_url = 'https://api.facebook.com/method/fql.query?format=json&query='
      request = "select like_count, share_count from link_stat where url ='#{page.fullpermalink(:canonical)}'"

      begin
        uri = URI.parse(URI.escape(base_url+request))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
        response = http.request(request)
        data = response.body
        logger.debug "Got : #{data}"

        decoded_data = JSON.parse(data)
        if decoded_data.count > 0 then
          @like_count = decoded_data.first['like_count']

          logger.debug "Read from FBQL : '@like_count'"
        end
      rescue
        @like_count = nil
      end
    else
      @like_count = nil
    end

    logger.debug "Information found on URL : '#{@comment_user}' said '#{@comment}'"

    logger.info "Notification mail for LIKE on #{type.to_s} '#{page.id}' sent to '#{owner.nickname}' - '#{owner.contact_email}' - '#{owner.id}'"
    if type == :dive || type == :picture
      subject = "Your #{type.to_s} on #{@dive.spot.name} #{@dive.spot.country.cname} is getting popular"
    elsif type == :blogpost
      subject = "Your blog post '#{@post.title}' is getting popular"
    end


    @recipient = owner
    @subtitle = "Looks like you've got new fans on Diveboard!"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    text = render_to_string 'notify_user/notify_like.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_like.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe
    #logger.debug "html:\n #{html}"

    send_from_sendgrid
    mail :to => owner.contact_email, :subject => subject do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end


  end


  def notify_comment(owner, page, arg_data, type)
    @data = arg_data
    @page = page
    @type = type.to_s
    @tag = "instant_notif_email"

    if type == :picture
      @dive = @page.dive
    elsif type == :dive
      @dive = @page
    elsif type == :blogpost
      @post = @page
    end

    if !owner.accept_instant_notif_email? then
      logger.debug "Notification to #{owner.nickname} [#{owner.id}] has not been sent due to user preference"
      return
    end

    if owner.contact_email.nil? then
      logger.warn "Notification to #{owner.nickname} [#{owner.id}] has not been sent due to contact mail being NIL"
      return
    end

    logger.debug "Filtering the notifications with '#{NOTIFICATION_MAIL_FILTER}'"

    if owner.contact_email.match(NOTIFICATION_MAIL_FILTER).nil? then
      logger.warn "Notification to #{owner.nickname} [#{owner.id}] @ [#{owner.contact_email}] has not been sent due to FILTERING"
      return
    end

    #TODO: check the user settings !!!

    # Fetches some information on the shared page
    base_url = 'https://api.facebook.com/method/fql.query?format=json&query='
    request = "select username, fromid, text, time from comment where object_id in (select comments_fbid from link_stat where url ='#{page.fullpermalink(:canonical)}') order by time DESC"

    begin
      uri = URI.parse(URI.escape(base_url+request))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
      response = http.request(request)
      data = response.body
      logger.debug "Got : #{data}"

      decoded_data = JSON.parse(data)
      if decoded_data.count > 0 then
        @comment_text = decoded_data.first['text']
        @comment_time = Time.at(decoded_data.first['time'].to_i)
        @comment_user = decoded_data.first['username']
        from_id = decoded_data.first['fromid']

        logger.debug "Read from FBQL : '#{@comment_user}' said '#{@comment}'"

        begin
          uri_graph = URI.parse(URI.escape("https://graph.facebook.com/v2.0/#{from_id}"))
          http_graph = Net::HTTP.new(uri_graph.host, uri_graph.port)
          http_graph.use_ssl = true
          request_graph = Net::HTTP::Get.new(uri_graph.path)
          response_graph = http_graph.request(request_graph)
          data_graph = response_graph.body
          logger.debug "Graph API request got : #{data_graph}"

          decoded_graph = JSON.parse(data_graph)
          if decoded_graph["name"] then
            @comment_user = decoded_graph["name"]
            @comment_picture = 'https://graph.facebook.com/v2.0/#{from_id}/picture?type=square'
          end
        rescue
        end
      end
    rescue
      @comment_text = nil
      @comment_time = nil
      @comment_user = nil
    end

    if @comment_user == 'Anonymous User' then
      @comment_user = nil
    end

    #Checking if the user who posted the page is a Diveboard user
    @comment_pager = User.where(:fb_id => from_id).first
    if !@comment_pager.nil? then
      @comment_picture = @comment_pager.picture_small
    end

    logger.debug "Information found on URL : '#{@comment_user}' said '#{@comment}'"

    logger.info "Notification mail for COMMENT on #{@type} '#{page.id}' sent to '#{owner.nickname}' - '#{owner.contact_email}' - '#{owner.id}'"
    if type == :dive || type == :picture
      subject =  "Your #{@type} on #{@dive.spot.name} #{@dive.spot.country.cname} has been commented"
    elsif type == :blogpost
      subject = "Your blog post '#{@post.title}' has been commented"
    end

    @recipient = owner
    @subtitle = "Looks like you've got new fans on Diveboard!"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)

    text = render_to_string 'notify_user/notify_comment.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_comment.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe
    #logger.debug "html:\n #{html}"

    send_from_sendgrid
    mail :to => owner.contact_email, :subject => subject do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end

  end


  def notify_dive_misssing_review user, shop
    @recipient = user
    @shop = shop
    @subtitle = "Don't forget to leave a review"
    @tag = "notify_dive_misssing_review"

    ## check if email is opt out
    return unless EmailSubscription.can_email?(@recipient, @tag)


    text = render_to_string 'notify_user/notify_dive_missing_review.text', :layout => false
    html = HtmlHelper::Inliner.new(
          (render_to_string 'notify_user/notify_dive_missing_review.html', :layout => 'email_notify_layout.html'),
          true,
          {},
          ['public/styles/newsletter.css']).execute.html_safe

    send_from_sendgrid
    mail :to => @recipient.contact_email,
      :subject => "#{user.nickname}, did you like diving with #{@shop.name}?" do |format|
      format.text{ render :text => text }
      format.html{ render :text => html }
    end
  end


  def newsletter letter, user, email_to
    @tag = "newsletter_email"


    ## check if email is opt out
    if user.nil?
      return unless EmailSubscription.can_email?(email_to, @tag)
      @recipient = email_to
    else
      return unless EmailSubscription.can_email?(user, @tag)
      @recipient = user
    end

    send_from_sendgrid
    mail :to => email_to, :subject => letter.subject do |format|
      format.html { render :inline => HtmlHelper::Tracker.new(HtmlHelper::Inliner.new((render_to_string :partial => 'notify_user/newsletter', :locals => {:user => user, :letter => letter, :date => Date.today}) , true, {}, ['public/styles/newsletter.css']).execute, false, "email", "newsletter", letter.id, begin user.shaken_id rescue "null" end).execute.html_safe }
    end
  end

  def test_email from, to, subject, content_html, content_text
    @tag = "test_email"
    Rails.logger.debug "Sending html email"
    mail :to => to, :subject => subject do |format|
      format.text{ render :text => content_text }
      format.html{ render :text => content_html.html_safe }
    end
  end

  def digest user, options = {}
    @user = user
    @recipient = user
    @tag = "weekly_digest_email"

    @start_date = options[:start_date] || (options[:delay] && (Time.now - options[:delay].to_i.days).to_date) || (Time.now - 14.days).to_date
    @notifications = @user.notifications.where('updated_at > :d', :d => @start_date).to_ary
    @notifications.reject! do |n| !n.should_notify? end
    @notifications.reject! do |n| !n.is_valid? end
    @notifications.uniq! do |notif| "#{notif.kind} #{notif.about_type} #{notif.about_id}" end
    @notifications.sort! do |a, b| b.created_at <=> a.created_at end
    @notifications_limit = 50

    @other_stuff = BlogPost.where('published = 1 and published_at > :d', :d => @start_date).order('published_at desc').limit(5)

    @great_pics = Picture.unscoped.where(:great_pic => true).group('user_id').order('created_at desc').limit(5).to_ary

    #Check if we can make the room now, or if he doesn't want to be disturbed
    Rails.logger.debug "Digest prepared for user #{user.id} (#{user.nickname}): #{@notifications.count} #{@other_stuff.count}"
    @notifications = [] if !user.accept_weekly_notif_email?
    @other_stuff = [] if !user.accept_weekly_digest_email?

    should_send_for_notif = @notifications.count > 1 || (@notifications.count > 0 && !user.accept_instant_notif_email?)
    should_send_for_other = @other_stuff.count > 0

    should_send_for_notif &&= (options[:prevent_notif] != true)
    should_send_for_other &&= (options[:prevent_other] != true)

    raise DBArgumentError.new "Nothing to send" if !should_send_for_notif && !should_send_for_other && !options[:force]

    subject = "#{@recipient.nickname}: What you may have missed this week on Diveboard - #{I18n.l Date.today.to_date, format: :long}"

    #text = render_to_string 'notify_user/digest.text', :layout => false
    html = HtmlHelper::Tracker.new(
            HtmlHelper::Inliner.new(
              (render_to_string 'notify_user/digest.html', :layout => 'email_notify_layout.html'),
              true,
              {},
              ['public/styles/newsletter.css']).execute,
            true, "email", "weekly_digest", Date.today.to_s, begin @user.shaken_id rescue "null" end).execute.html_safe

    #logger.debug "html:\n #{html}"

    send_from_sendgrid
    mail :to => user.contact_email, :subject => subject do |format|
#      format.text{ render :text => text }
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
