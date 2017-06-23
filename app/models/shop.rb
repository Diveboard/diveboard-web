require 'private_attrs'
require 'uri'
## IMPORTANT

## flag_moderate_private_to_public defines the shop states
## nil <= it's a PUBLIC SPOT
## true <= it's a PRIVATE SPOT NOT YET MODERATED
## false <== it's a private shop that will NOT BE MODERATED
## false and private_user_id empty <= it's been merged and should be disregarded




class Shop < ActiveRecord::Base
  extend FormatApi
  has_many :dives, :class_name => 'Dive'
  has_many :reviews
  has_many :advertisements, :through => :user_proxy
  has_one :user_proxy, :class_name => 'User', :foreign_key => :shop_proxy_id
  belongs_to :country, :foreign_key => :country_code, :primary_key => :ccode
  has_many :shop_widgets, :inverse_of => :shop
  alias :dive_ids :dife_ids
  has_many :good_to_sell, :order => 'goods_to_sell.realm, goods_to_sell.order_num'
  delegate :crop_picture, :to => :user_proxy
  delegate :currency, :to => :user_proxy
  delegate :currency?, :to => :user_proxy
  delegate :currency_symbol, :to => :user_proxy
  has_many :signatures, :as => :signby
  has_many :shop_details
  has_many :shop_q_and_a
  has_many :activity_followings

  has_many :emails_marketing, :as => :target, :class_name => 'EmailMarketing', :source=> :target, :source_type => 'Shop'


  cattr_accessor :userid  ## this defines the current user context

  before_save :compute_score
  after_create :create_default_question

  define_format_api :public => [ :id, :shaken_id, :name, :lat, :lng, :address, :city, :country_code, :email, :web, :phone, :logo_url, :category, :vanity_url, :permalink, :fullpermalink, full_permalink: ->(s){s.fullpermalink} ],
                    :private => [ ],
                    :technical => [ :shaken_id, :displayed_set, :currency, :currency_symbol, :currency_first, :allowed_ads, :price_ref_incl_tax, :delay_bookings,
                      :user_proxy_id => Proc.new do |s| s.user_proxy.id end ],
                    :search_light => [ :dive_ids, :dive_count, :positive_reviews, :negative_reviews, :overall_rating, :score, :can_sell?, :about_html, :marks, country_name: lambda {|s| s.country.name}],
                    :search_full => [],
                    :search_full_server => [ dives: lambda {|s| s.dives.limit(10).to_api(:search_full_server_l1)}],
                    :search_full_server_l1 => [ ],
                    :search_full_server_l2 => [ ]

  define_api_private_attributes :allowed_ads

  define_api_includes :* => [:public], :search_full => [:search_light], :search_full_server => [:search_full], :search_full_server_l1 => [:search_full], :search_full_server_l2 => [:search_full]

  define_api_updatable_attributes %w(about_html address city country_code email currency openings lat lng phone web category facebook twitter google_plus nearby crop_picture favorite_dives name realm_home realm_dive init_realm_dive paypal_id)
  define_api_updatable_attributes_rec 'owned_dives' => Dive, 'all_dive_goods' => GoodToSell
  define_api_searchable_attributes %w(name)

  private_setters :paypal_token, :paypal_secret

  ALLOWED_CATEGORIES = [nil, 'Dive Center', 'Dive Club', 'Dive instructor', 'Dive Shop', 'Travel Agency', 'Liveaboard', 'Hotel', 'Manufacturer']

  #Activated realms => remove realm here to disactivate its display everywhere
  AVAILABLE_REALMS = ["home", "review", "profile", "staff", "dive", "marketing", "care", "welcome"] #, "store", "gear", "travel"]
  #Realms available for editing (if AVAILABLE)
  EDITABLE_REALMS = ["home", "profile", "staff", "care", "dive", "marketing", "welcome"]#, "gear", "travel", "ads"]
  #Those realms will be always visible for public
  DEFAULT_REALMS =  ["profile", "review"]

  REALMS_WITH_WIDGETS = ['home', 'gear', 'travel']
  DEFAULT_AVAILABLE_WIDGETS = ['WidgetText', 'WidgetPictureBanner']#, 'WidgetReview', 'WidgetListDives']

  NO_PICTURE = ROOT_URL+"img/shop/icon_shop_default.png"

  QUESTIONS_FOR_FAQ = ["staff", "boat", "shore_dives", "deco_chamber", "tanks", "gases", "gear", "gear_sales", "gear_maintenance", "services", "payment", "best_period", "hotels", "transfers", "parking", "other_activities"]

  def is_visible_for?(userid)
    return true if self.status == :public
    return true if self.private_user_id == userid
    return false
  end


  def is_private_for?(options={})
    return true if !user_proxy.nil? && user_proxy.is_private_for?(options)
    return false
  end

  def is_claimed?
    return false if self.user_proxy.nil?
    self.user_proxy.group_memberships.each do |m|
      return true if m.role == 'admin'
    end
    return false
  end

  def owners
    users = []
    return [] if self.user_proxy.nil?
    self.user_proxy.group_memberships.each do |m|
      users.push m.user if m.role == 'admin'
    end
    return users
  end

  def add_owner(u)
    u = User.find(u) if u.class == Fixnum 

    if Membership.where({:user_id => u.id, :group_id => self.user_proxy.id, :role => 'admin'}).count == 0 then
      Membership.create :user_id => u.id, :group_id => self.user_proxy.id, :role => 'admin'
      Notification.create :kind => 'shop_granted_rights', :user_id => u.id, :about => self
      self.reload
    end

  end

  def shaken_id
    "K#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "K"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end



  def address=(val)
    val=nil if val.blank?
    write_attribute(:address, val)
  end

  def email=(val)
    val=nil if val.blank?
    write_attribute(:email, val)
  end

  def email
    read_attribute(:email) || "missing_shop_email@diveboard.com"
  end

  def web=(val)
    if val.nil?
      val=nil
    else
      val = "http://#{val}" unless val.match(/^(http|https):\/\//)
      clean_uri =  val.match(URI::regexp)
      raise DBArgumentError.new :ill_formed_url, :url => val if clean_uri.nil?
      val = clean_uri[0]
    end
    write_attribute(:web, val)
  end

  def web
    val = read_attribute(:web)
    return nil if val.nil? || val == "" || val == "http://"
    val = "http://#{val}" unless val.match(/^(http|https):\/\//)
    return val
  end

  def phone=(val)
    val=nil if val.blank?
    write_attribute(:phone, val)
  end

  def nearby=(val)
    val=nil if val.blank?
    write_attribute(:nearby, val)
  end

  def lat=(val)
    val=nil if val.blank?
    val = val.to_f unless val.nil?
    write_attribute(:lat, val)
  end

  def lng=(val)
    val=nil if val.blank?
    val = val.to_f unless val.nil?
    write_attribute(:lng, val)
  end


  def url
    self.web
  end

  def dive_count
    dive_ids.length
  end

  def ensure_url!
    return if self.web.nil?
    if !self.web.match(/^http:\/\//) then
      self.web = "http://"+self.web
      self.save!
    end
    return self.web
  end

  def positive_reviews
    self.public_reviews.where("recommend = true").count
  end

  def negative_reviews
    self.public_reviews.where("recommend = false").count
  end

  def public_reviews
    self.reviews.where("spam != true AND reported_spam != true")
  end

  def category=(val)
    raise DBArgumentError.new "Value not allowed", val: val.inspect unless ALLOWED_CATEGORIES.include?(val)
    Rails.logger.debug "Updatig shop #{self.id} with category #{val}"
    write_attribute(:category, val)
  end

  def category
    c = read_attribute(:category)
    return c unless c.nil?
    return "Dive Center"
  end

  def country
    c = read_attribute(:country_code)
    return Country.blank if c.nil?
    cnt = Country.where(:ccode => c.upcase).first
    return Country.blank if cnt.nil?
    return cnt
  end

  def crop_picture
    nil
  end

  def crop_picture=(img)
    raise DBArgumentError.new "Cannot update picture for shop : no user linked", id: id if user_proxy.nil?
    user_proxy.crop_picture=img
    logger.debug "pict from shop : #{user_proxy.pict}"
    user_proxy.save!
  end


  def name
    if user_proxy.nil?
      read_attribute(:name)
    else
      user_proxy.nickname
    end
  end

  def nickname
    name
  end

  def name=(val)
    raise DBArgumentError.new "Cannot update nickname for shop : nickname cannot be null", id: id if val.nil?
    if !user_proxy.nil?
      user_proxy.nickname = val
      user_proxy.save
    end
    logger.debug " nickname of shop #{self.id} updated with #{val}"
    write_attribute(:name, val)
  end

  def picture
    return user_proxy.picture_large if user_proxy && user_proxy.pict
    return Shop::NO_PICTURE
  end

  def logo_url
    return user_proxy.picture_large unless user_proxy.nil?
    return User::NO_PICTURE
  end

  def fullpermalink *args
    return user_proxy.fullpermalink(*args) unless user_proxy.nil? || user_proxy.vanity_url.nil?
    return nil if web.blank?
    return web if web.match(/^https?:\/\//)
    return "http://#{web}"
  end

  def permalink
     return user_proxy.permalink unless user_proxy.nil? || user_proxy.vanity_url.nil?
     return nil
  end

  def vanity_url
    return user_proxy.vanity_url unless user_proxy.nil?|| user_proxy.vanity_url.nil?
    return nil
  end

  def favorite_dives=(list)
  end

  def favorite_dives
    return user_proxy.favorite_dives unless user_proxy.nil?
    return []
  end

  def owned_dives
    return user_proxy.dives unless user_proxy.nil?
    return []
  end

  def owned_dives=(list)
    unless user_proxy.nil? then
      user_proxy.dives=list
      user_proxy.save!
    end
    list
  end

  def public_dives
    return dives.reject do |dive| dive.privacy == 1 end
  end

  # Only accept valid country codes
  def country_code=(ccode)
    if ccode.blank? then
      write_attribute(:country_code, nil)
      user_proxy.location = nil unless user_proxy.nil?
    else
      raise DBArgumentError.new 'Invalid country code' if Country.where(:ccode => ccode.upcase).count == 0
      write_attribute(:country_code, ccode.upcase)
      user_proxy.location = ccode.downcase unless user_proxy.nil?
    end
    user_proxy.save! unless user_proxy.nil?
  end

  # Defining setters to replace blank string by nil for some attributes
  [:about_html, :openings, :twitter, :google_plus].each do |non_blank_attr_name|
    send :define_method, "#{non_blank_attr_name}=" do |text|
      if text.blank? then
        write_attribute(non_blank_attr_name, nil)
      else
        write_attribute(non_blank_attr_name, text)
      end
    end
  end

  def facebook=(text)
    if text.blank? then
      write_attribute(:facebook, nil)
    elsif text.strip.match /^https?:\/\// then
      write_attribute(:facebook, text.strip)
    else
      write_attribute(:facebook, "http://"+text.strip)
    end
  end

  # Defining the mark_* functions : they are all the same so let's stay DRY
  [:mark_orga, :mark_friend, :mark_secu, :mark_boat, :mark_rent].each do |mark_attr_name|
    send :define_method, mark_attr_name do
      sum = 0.0
      count = 0
      reviews.each do |r|
        val = r.send mark_attr_name
        if !val.nil? then
          sum += val
          count += 1
        end
      end
      return nil if count == 0
      return {:mark => (sum / count).round(1).to_f, :count => count}
    end
  end

  def marks
    m = {}
    [:mark_orga, :mark_friend, :mark_secu, :mark_boat, :mark_rent].each do |mark|
      m[mark] = self.send mark
    end
    return m
  end

  def currency=val
    u=self.user_proxy
    u.currency = val
    u.save!
  end

  def currency_first
    self.user_proxy.currency_first
  end

  def overall_rating
    marks = reviews.reject do |r| r.spam end .map &:average_mark
    return nil if marks.count == 0
    return marks.sum / marks.count
  end

  def create_proxy_user!
    self.save! if new_record?
    raise DBArgumentError.new "Must be called once the shop has a name" if self.name.nil?
    raise DBArgumentError.new "Only public spots are allowed a proxy_user" unless self.status == :public

    if !self.user_proxy.nil? then
      Rails.logger.debug "create_proxy_user! has been called for shop '#{self.name}' (#{self.id}) but already has a user (#{self.user_proxy.id})"
      if self.user_proxy.vanity_url.nil?
        self.user_proxy.create_shop_vanity!
      end
      return self.user_proxy
    else
      u = User.new
      u.nickname = self.name
      u.location = country_code && country_code.downcase
      u.shop_proxy_id = self.id
      u.create_shop_vanity!
      u.preferred_locale = I18n.locale

      Rails.logger.info "Creating user for shop '#{self.name}' (#{self.id}) with vanity '#{u.vanity_url}'"
      u.save!
      Rails.logger.debug "User for shop '#{self.name}' (#{self.id}) has id #{u.id}"
      return u
    end
  end

  def merge_into newid
    ##will redirect all dives pointing to self to id
    dest = Shop.find(newid) ## this will raise if no such shop
    raise DBArgumentError.new "cannot merge a public shop into a non-public shop" if self.status == :public && dest.status != :public
    raise DBArgumentError.new "cannot merge a private shops with different owners" if self.status != :public && dest.status != :public && self.private_user_id != dest.private_user_id
    raise DBArgumentError.new "This shop is public and user needs to be cleared from dives" if !self.user_proxy.nil? && !self.user_proxy.dives.empty?
    raise DBArgumentError.new "This shop is public and user needs to be cleared from memberships" if !self.user_proxy.nil? && !self.user_proxy.group_memberships.blank?

    ##move dives from users
    self.dives.each do |d|
      d.shop_id = newid
      d.save
    end

    
    #move signature requests
    self.signatures.each do |s|
      s.signby_id = newid
      s.save rescue s.destroy
    end

    ##move email history
    self.emails_marketing.each do |m|
      m.recipient_id = newid if m.recipient_id == self.id
      m.target_id = newid if m.target_id == self.id
      m.save rescue m.destroy
    end


    if self.user_proxy
      Membership.where(:group_id => user_proxy.id).each do |m|
        begin
          m.group_id = dest.user_proxy.id
          m.save
        rescue

        end
      end

      self.user_proxy.destroy
    end

    self.disable_shop
  end

  def disable_shop
    self.reload
    raise DBArgumentError.new "Shop is being used in dives" if !self.dives.empty?
    raise DBArgumentError.new "Shop still has a public url" if !self.user_proxy.nil? && !self.user_proxy.vanity_url.nil?

    self.flag_moderate_private_to_public = false
    self.private_user_id = nil

    self.save
  end

  def make_private
    ##disable the user_proxy
    if !(u = self.user_proxy).nil?
      u.vanity_url = nil
      u.save
    end

    ##get the list of user using those dives
    user_list = self.dives.map(&:user_id).uniq
    if user_list.empty?
      self.disable_shop
    else
      user_list.each_with_index  do |uid,i|
        if i > 0
          s = self.duplicate
        else
          s = self
        end
        s.private_user_id = uid
        s.flag_moderate_private_to_public = false
        s.save!
      end
    end
  end

  def make_public
    raise DBArgumentError.new "Cannot make public a spot without name" if self.name.nil?

    self.flag_moderate_private_to_public = nil
    self.private_user_id = nil
    self.save!
    self.create_proxy_user!
  end

  def status
    return :public if flag_moderate_private_to_public.nil?
    return :awaiting_moderation if flag_moderate_private_to_public == true
    return :private if flag_moderate_private_to_public == false && !private_user_id.nil?
    return :disabled if flag_moderate_private_to_public == false && private_user_id.nil?
  end

  def duplicate
    #This creates a new spot with no owner in the same moderation state and returns the new spot
    newshop = Shop.new(self.attributes)
    newshop.private_user_id = nil ## don't want to keep fake ownerships
    newshop.save!
    return newshop
  end

  def can_manage_widgets?
    return true
  end

  def displayed_set
    if can_manage_widgets? then
      return 'custom'
    else
      return 'default'
    end
  end

  def widgets
    list_widgets = []
    if can_manage_widgets? then

      list_widgets = shop_widgets.where(:shop_id => self.id, :set => 'custom')
      if list_widgets.blank? then
        list_widgets = shop_widgets.where(:shop_id => self.id, :set => 'default')
        if list_widgets.blank? then
          list_widgets = ShopWidget.where(:shop_id => nil, :set => 'default')
        end
        list_widgets = ShopWidget.copy_set list_widgets, self.id, 'custom'
      end

    else
      list_widgets = shop_widgets.where(:shop_id => self.id, :set => 'default')
      if list_widgets.blank? then
        list_widgets = ShopWidget.where(:shop_id => nil, :set => 'default')
        list_widgets = ShopWidget.copy_set list_widgets, self.id, 'default'
      end
    end

    grouped_widgets = {}
    list_widgets.group_by(&:realm).each do |key, vals|
      grouped_widgets[key] = vals.sort do |a,b| a.position <=> b.position  end
    end
    grouped_widgets
  end

  def available_widget_types
    return DEFAULT_AVAILABLE_WIDGETS
  end

  def view_realms
    list = DEFAULT_REALMS.dup

    Rails.logger.debug "DEFAULT_REALMS: #{list.inspect}"

    list.unshift "home" if self.realm_home
    list.push "dive" if self.realm_dive && !self.all_dive_goods.blank?

    #AVAILABLE REALMS is the list of activated realms
    list.reject! do |r| !AVAILABLE_REALMS.include?(r) end

    return list.uniq
  end

  def edit_realms
    Rails.logger.debug "EDITABLE_REALMS: #{EDITABLE_REALMS.inspect}"
    list = EDITABLE_REALMS.reject do |r| !AVAILABLE_REALMS.include?(r) end
      Rails.logger.debug "PLAN: #{self.subscribed_plan.inspect}"
      #list = list.reject do |r| r=='care' end if self.subscribed_plan.name == 'free'
      Rails.logger.debug list.inspect
    return list
  end

  def init_realm_dive=(detail)
    return unless self.realm_dive.nil? || self.all_dive_goods.blank?

    GoodToSell.transaction do
      order_id = 0
      services = YAML.load_file('config/dive_services.yml')
      services.each do |cat1_hash|
        order_id += 1
        cat1 = cat1_hash.keys.first
        Rails.logger.debug "Considering #{cat1}"
        items = cat1_hash[cat1]
        if cat1 == 'Dives' || detail["service_#{cat1.underscore}"] then
          if cat1 == 'Courses' then
            items.each do |cat2, items2|
              next unless detail["cert_#{cat2.underscore}"]
              items2.each do |item|
                GoodToSell.create({
                  :title => "#{cat2} - #{item}",
                  :shop_id => self.id,
                  :realm => 'dive',
                  :cat1 => cat1,
                  :cat2 => cat2,
                  :currency => self.currency,
                  :order_num => order_id
                })
              end
            end
          else
            items.each do |item|
              GoodToSell.create({
                :title => item,
                :shop_id => self.id,
                :realm => 'dive',
                :cat1 => cat1,
                :currency => self.currency,
                :order_num => order_id
              })
            end
          end
        end
      end
      self.realm_dive=true
    end
  end

  def all_dive_goods
    reordered_goods = []
    goods = self.good_to_sell.to_ary.reject do |g| g.realm == 'Dive' end
    grouped_goods = goods.group_by &:cat1
    goods.map(&:cat1).uniq.each do |cat1|
      reordered_goods += grouped_goods[cat1]
    end
    return reordered_goods
  end

  def public_dive_goods
    self.all_dive_goods
  end

  def all_dive_goods=(list)
    GoodToSell.transaction do
      self.all_dive_goods.reject do |good| list.include? good end .map &:destroy
      self.good_to_sell << list
    end
  end

  def allowed_ads
    return 5
  end

  def can_sell? opt=nil
    #can_sell? :dive => are dive sells active
    #can_sell? => are any kind of sells active
    return false unless self.has_feature?(:online_booking)
    return true if self.is_claimed? && self.paypal_id && self.paypal_secret && self.paypal_token
    return false
  end

  #Delay in hours to allow bookings. Use 0 for only dates in the future, use -1 to disable totally.
  #Note that since dates for dives are taken at 00:01, delay_bookings = 24 means a delay of 2 days
  def delay_bookings
    return 4*24
  end

  def price_ref_incl_tax
    return true
  end

  def current_baskets
    Basket.where(:shop_id => self.id, :status => ['paid', 'confirmed', 'hold'])
  end

  def current_messages
    InternalMessage.where(:to_id => self.user_proxy.id, :status => ['new'])
  end

  def customers
    customers = {}
    User.joins(:baskets).where('baskets.shop_id' => self.id, 'baskets.status' => ['paid', 'hold', 'confirmed', 'delivered', 'cancelled']).each do |customer|
      customers[customer] ||= {}
      customers[customer][:nb_orders] ||= 0
      customers[customer][:nb_orders] += 1
    end

    Dive.includes(:user).where(:shop_id => self.id, :privacy => false).each do |dive|
      customers[dive.user] ||= {}
      customers[dive.user][:nb_dives] ||= 0
      customers[dive.user][:nb_dives] += 1
    end

    Review.includes(:user).where(:shop_id => self.id, :anonymous => false).each do |review|
      customers[review.user] ||= {}
      customers[review.user][:review] = review
    end

    customers.each do |customer, stats|
      stats[:nb_dives] ||= 0
      stats[:nb_orders] ||= 0
    end

    return customers
  end

  def history_with_customer user, in_reply_to=nil
    history = ShopCustomerHistory.where(:shop_id => self.id, :user_id => user.id).order(:registered_at).map(&:stuff)
    return history if in_reply_to.nil?
    return history.reject do |stuff|
      stuff.in_reply_to != in_reply_to rescue true
    end
  end

  def paypal_id=val
    return if read_attribute(:paypal_id) == val
    write_attribute(:paypal_id, val)
    write_attribute(:paypal_token, nil)
    write_attribute(:paypal_secret, nil)
  end

  def paypal_validate_id(sign, token, verifier)
    raise DBArgumentError.new "Invalid signature for shop" unless sign == Digest::MD5.hexdigest("P3rM1$$10|\\| F0r: #{7*self.id} U><0r: #{self.paypal_id}")

    begin
      request_headers = {
        'X-PAYPAL-SECURITY-USERID' => Rails.application.config.paypal[:api_username],
        'X-PAYPAL-SECURITY-PASSWORD' => Rails.application.config.paypal[:api_password],
        'X-PAYPAL-SECURITY-SIGNATURE' => Rails.application.config.paypal[:api_signature],
        'X-PAYPAL-APPLICATION-ID' => Rails.application.config.paypal[:app_id],
        'X-PAYPAL-REQUEST-DATA-FORMAT' => 'JSON',
        'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON'
      }

      request = {
        "token" => token,
        "verifier" => verifier
      }

      #Making the call
      uri = URI.parse(URI.escape('https://'+Rails.application.config.paypal[:api_host]+'/Permissions/GetAccessToken'))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri.path, ActiveSupport::JSON.encode(request), request_headers)
      Rails.logger.info "PAYPAL RESPONSE : #{response.body}"

      data = ActiveSupport::JSON.decode(response.body)

      if data['responseEnvelope']['ack'] == "Success" && data['token'] && data['tokenSecret'] then
        #everything OK, we'll be able to do:
        #write_attribute(:paypal_token, data['token'])
        #write_attribute(:paypal_secret, data['tokenSecret'])
        token = data['token']
        token_secret = data['tokenSecret']
      elsif data['responseEnvelope']['error']
        raise DBTechnicalError.new "Paypal error", error_id: data['responseEnvelope']['error'][0]['errorId'], message: data['responseEnvelope']['error'][0]['message']
      else
        Rails.logger.debug data.inspect
        raise DBTechnicalError.new "Paypal request to RequestPermissions failed"
      end

      #Get the correct Paypal ID
      url = 'https://'+Rails.application.config.paypal[:api_host]+'/Permissions/GetBasicPersonalData'

      signature = OauthSignature.new Rails.application.config.paypal[:api_username],
                            Rails.application.config.paypal[:api_password],
                            token,
                            token_secret,
                            url

      request2_headers = {
        'X-PAYPAL-AUTHORIZATION' => signature.authorization_string,
        'X-PAYPAL-APPLICATION-ID' => Rails.application.config.paypal[:app_id],
        'X-PAYPAL-REQUEST-DATA-FORMAT' => 'JSON',
        'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON'
      }

      request2 = {'attributeList' => {'attribute' => ['http://axschema.org/contact/email']}}

      #Making the call
      uri = URI.parse(URI.escape(url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response2 = http.post(uri.path, ActiveSupport::JSON.encode(request2), request2_headers)
      Rails.logger.info "PAYPAL RESPONSE : #{response2.body}"

      data2 = ActiveSupport::JSON.decode(response2.body)

      key = data2['response']['personalData'][0]['personalDataKey'] rescue nil
      email = data2['response']['personalData'][0]['personalDataValue'] rescue nil

      if data2['responseEnvelope']['ack'] == "Success" && !email.blank? && key == 'http://axschema.org/contact/email' then
        write_attribute(:paypal_id, email)
        write_attribute(:paypal_token, data['token'])
        write_attribute(:paypal_secret, data['tokenSecret'])
        save!
      elsif data2['responseEnvelope']['error']
        raise DBTechnicalError.new "Paypal error", error_id: data['responseEnvelope']['error'][0]['errorId'], message:data['responseEnvelope']['error'][0]['message']
      else
        raise DBTechnicalError.new "Paypal request to RequestPermissions failed"
      end

    rescue
      Rails.logger.error "Paypal request failed (#{$!.message})"
      Rails.logger.debug $!.backtrace.join "\n"
      raise DBArgumentError.new "Paypal request failed", message: $!.message
    end
  end

  def paypal_gen_permission_request_url
    begin
      request_headers = {
        'X-PAYPAL-SECURITY-USERID' => Rails.application.config.paypal[:api_username],
        'X-PAYPAL-SECURITY-PASSWORD' => Rails.application.config.paypal[:api_password],
        'X-PAYPAL-SECURITY-SIGNATURE' => Rails.application.config.paypal[:api_signature],
        'X-PAYPAL-APPLICATION-ID' => Rails.application.config.paypal[:app_id],
        'X-PAYPAL-REQUEST-DATA-FORMAT' => 'JSON',
        'X-PAYPAL-RESPONSE-DATA-FORMAT' => 'JSON'
      }

      #r_url = self.fullpermalink(:locale)+"/edit/store"
      r_url = self.fullpermalink(:locale)+"/edit/services"
      sign = Digest::MD5.hexdigest("P3rM1$$10|\\| F0r: #{7*self.id} U><0r: #{self.paypal_id}")
      request = {
        "scope" => ["EXPRESS_CHECKOUT", "AUTH_CAPTURE", "REFUND", "MOBILE_CHECKOUT", "DIRECT_PAYMENT", "TRANSACTION_DETAILS", "TRANSACTION_SEARCH", "ACCESS_BASIC_PERSONAL_DATA"],
        "callback" => "#{ROOT_URL}api/paypal/permission_return?i=#{self.shaken_id}&s=#{sign}&r=#{url_encode(r_url)}"
      }

      #Making the call
      uri = URI.parse(URI.escape('https://'+Rails.application.config.paypal[:api_host]+'/Permissions/RequestPermissions'))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri.path, ActiveSupport::JSON.encode(request), request_headers)
      Rails.logger.info "PAYPAL RESPONSE : #{response.body}"

      data = ActiveSupport::JSON.decode(response.body)

      Rails.logger.debug data.inspect

      if data['responseEnvelope']['ack'] == "Success" && data['token'] then
        return Rails.application.config.paypal[:api_3t_url] + "?cmd=_grant-permission&request_token=#{data['token']}"
      elsif data['responseEnvelope']['error']
        raise DBTechnicalError.new "Paypal error", error_id: data['responseEnvelope']['error'][0]['errorId'], message: data['responseEnvelope']['error'][0]['message']
      else
        Rails.logger.debug data.inspect
        raise DBTechnicalError.new "Paypal request to RequestPermissions failed"
      end
      Rails.logger.debug 1

    rescue
      Rails.logger.error "Paypal request failed (#{$!.message})"
      Rails.logger.debug $!.backtrace.join "\n"
      raise DBArgumentError.new "Paypal request failed", message: $!.message
    end
  end

  def subscribed_plan include_pending=false
    default_plan = SubscriptionPlan.where(:category => 'plan_pro', :name => 'free').first
    if include_pending
      payments = Payment.where(:status => ['confirmed','pending','suspended'], :category => 'plan_pro', :shop_id => self.id)
    else
      payments = Payment.where(:status => 'confirmed', :category => 'plan_pro', :shop_id => self.id)
    end

    return payments.last.subscription_plan rescue default_plan
  end

  def has_feature? feature
    case feature
    when :reply_review, :community_dashboard then
      return (subscribed_plan.name != 'free')
    else true
    end
  end

  def unsubscribe_plan
    payments = Payment.where(:status => ['confirmed','pending','suspended'], :category => 'plan_pro', :shop_id => self.id)
    payments.each do |p|
      p.stop_subscription!
    end
  end

  def pending_signatures
    self.signatures.where(:rejected => false).where(:signed_date => nil)
  end

  def has_picture?
    self.proxy_user.has_picture? rescue false
  end

  def contact_email
    ## compatibility form mailers
    email
  end

  def contact_email?
    return false if self.contact_email.nil? || self.contact_email.match(/\@diveboard.com$/)
    return true
  end

  def price_range
    min = GoodToSell.where("realm = \"dive\" AND cat1 = \"Dives\" AND status != \"deleted\" AND total IS NOT NULL AND total != 0 AND shop_id = ?", id).order("total ASC").limit(1).first
    max = GoodToSell.where("realm = \"dive\" AND cat1 = \"Dives\" AND status != \"deleted\" AND total IS NOT NULL AND total != 0 AND shop_id = ?", id).order("total DESC").limit(1).first
    return {min: min, max: max}
  end

  def rating
    if reviews.empty?
      return nil
    end
    count = 0.0;
    total = 0.0;
    reviews.each do |review|
      if review.mark_orga != nil
        count += 1
        total += review.mark_orga
      end
      if review.mark_friend != nil
        count += 1
        total += review.mark_friend
      end
      if review.mark_secu != nil
        count += 1
        total += review.mark_secu
      end
      if review.mark_boat != nil
        count += 1
        total += review.mark_boat
      end
      if review.mark_rent != nil
        count += 1
        total += review.mark_rent
      end
    end
    if count != 0
      total = ((total*2.0).round / 2.0 )/ count
      finaltot = total
    end
    return finaltot
  end

  def dive_pictures limit=0
    p = Picture.joins("LEFT JOIN picture_album_pictures ON pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON picture_album_pictures.picture_album_id = dives.album_id").where("dives.shop_id = ?", id)
    if limit != 0
      p = p.limit(limit)
    end
    return p
  end

  def gallery_pictures limit=0
    p = Picture.joins("LEFT JOIN picture_album_pictures ON pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON picture_album_pictures.picture_album_id = dives.album_id").where("dives.shop_id = ?", id)
    if limit != 0
      p = p.limit(limit)
    end
    return p
  end

  def spots
    s = Spot.joins("LEFT JOIN dives ON spots.id = dives.spot_id").where("dives.shop_id = ?", id).uniq
  end

  def affiliated
    shop_details.where("kind = 'affiliation'").map(&:value)
  end

  def languages
    shop_details.where("kind = 'lang'")..order("id").map(&:value)
  end

  def i18nLanguages lang
    I18nLanguages.joins("LEFT JOIN shop_details ON i18n_languages.code3 = shop_details.value").where("kind = 'lang' AND shop_id = ? AND lang = ?", id, lang).order("shop_details.id")
  end

  def teams
    shop_details.where("kind = 'team'").order("id").map(&:value)
  end

  def faqs
    shop_q_and_a.order("official DESC, position")
  end

  def area
    Area.where("(? BETWEEN minLat AND maxLat) AND (? BETWEEN minLng AND maxLng)", lat, lng).first
  end

  def follow_count
    activity_followings.count
  end

  def compute_score
    return true if @computed_score
    self.score = 0
    self.score += self.dives.count / 8
    self.score += self.overall_rating * 10 if self.overall_rating
    self.score += self.positive_reviews * 3
    self.score -= self.negative_reviews * 5
    self.score += 5 if self.good_to_sell.count > 0
    self.score += 5 if self.user_proxy.pict rescue false
    self.score += 30 if self.can_sell?
    @computed_score = self.score
    return true #we wouldn't want to break the save call
  end


private

  def create_default_question
    QUESTIONS_FOR_FAQ.each do |q|
      ShopQAndA.create(question: q, answer: "", shop: self, language: "en", official: true)
    end
  end

end
