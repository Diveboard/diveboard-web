class ExternalUser < ActiveRecord::Base
  extend FormatApi

  has_many :dives_buddies, as: :buddy
  has_many :users_buddies, as: :buddy
  has_many :signatures, as: :signby
  has_many :emails_marketing, :as => :target, :class_name => 'EmailMarketing', :source=> :target, :source_type => 'ExternalUser'


  define_format_api :public => [
          :picture, :picture_small, :picture_large, :nickname, :id, :fb_id, :email
        ],
        :private => [ ],
        :search_light => [  ],
        :search_full => [  ]

  define_api_includes :* => [:public], :search_full => [:search_light]

  define_api_updatable_attributes %w( fb_id nickname email picturl )
  define_api_private_attributes :fb_id, :id, :email

  before_save :ensure_has_name


  def is_private_for?(options={})
    return true if options[:private]
    return true if options[:action] == :create
    return true if options[:caller].ext_buddy_ids.include? self.id rescue false
    return false
  end

  def is_accessible_for?(options={})
    return is_private_for? options
  end

  NO_PICTURE = ROOT_URL+"img/no_picture.png"

  def self.find_or_create owner, args_init
    return nil unless Hash === args_init

    #We don't want blank, but only nil
    args = {}
    args_init.each do |key, val|
      args[key] = val.strip.gsub(/ +/,' ') rescue val unless val.blank?
    end
    args['email'] = args['email'].downcase unless args['email'].blank?

    if !args['id'].blank? then
      return ExternalUser.find(args['id'])
    elsif !args['ex_id'].blank? then
      return ExternalUser.find(args['ex_id'])
    elsif !args['fb_id'].blank? then
      existing = User.where(:fb_id => args['fb_id']).first
      return existing unless existing.nil?
      existing = ExternalUser.where(:fb_id => args['fb_id']).first
      return existing unless existing.nil?
      res = Koala::HTTPService.make_request args['fb_id'].to_s, {}, "GET"
      if res.status == 200
        data = JSON.parse(res.body)
        return ExternalUser.create :fb_id => args['fb_id'], :nickname => data['name']
      else
        Rails.logger.warn "Error while trying to create FB buddy from id #{args['fb_id']} : #{res.body rescue nil}"
      end
    elsif !args['db_id'].blank?
      return User.find(args['db_id'].to_i)
    elsif !args['email'].blank? || !args['name'].blank? || !args['nickname'].blank? then
      owner.ext_buddies.each do |b|
        return b if begin
          b.nickname.downcase == (args['name'].downcase || args['nickname'].downcase) && b.email == args['email']
        rescue NoMethodError => e
          b.nickname == (args['name']||args['nickname']) && b.email == args['email']
        end
      end
    end
    Rails.logger.debug "Creating ExternalUser from #{args.to_json}"
    return ExternalUser.create! :fb_id => args['fb_id'], :nickname => (args['name']||args['nickname']), :email => args['email'], :picturl => args['picturl'] rescue nil
  end

  def self.bulk_create_from_emails owner, text
    recognised = text.scan /(?:,|\n|^) *"?([^@<,\n"]*)"? *(?:[,\n< ]|^)([a-zA-Z0-9.!$&*+=^_{|}~#-]+@[a-zA-Z0-9._-]+)>?/
    users = []
    recognised.each do |name, email|
      u = find_or_create owner, {'email' => email, 'name' => name}
      users.push( u )
    end
    return users
  end

  def permalink
    return nil
  end
  def fullpermalink *args
    return nil
  end

  def picture
    if self.fb_id then
      return "http://graph.facebook.com/v2.0/#{fb_id}/picture?type=normal"
    elsif self.picturl then
      return self.picturl
    else
      return NO_PICTURE
    end
  end

  def picture_small
    if self.fb_id then
      return "http://graph.facebook.com/v2.0/#{fb_id}/picture?type=square"
    elsif self.picturl then
      return self.picturl
    else
      return NO_PICTURE
    end
   end

  def picture_large
    if self.fb_id then
      return "http://graph.facebook.com/v2.0/#{fb_id}/picture?type=large"
    elsif self.picturl then
      return self.picturl
    else
      return NO_PICTURE
    end
  end

  def has_picture?
    return true if self.fb_id || (!self.picturl.blank? && self.picturl != "/img/no_picture.png")
    return false
  end

  def contact_email
    return self.email
  end

  def ensure_has_name
    return unless self.nickname.nil?
    Rails.logger.debug "External user has no nickname, he needs one"
    if !self.fb_id.nil?
      Rails.logger.debug "External user has an fb_id #{self.fb_id}"
      update_name_from_fb
    end
    if !self.email.nil?
      self.nickname = self.email.split("@")[0]
    end
    return false if self.nickname.nil?
    return true
  end

  def update_name_from_fb
    require 'curb'
    fburl = "http://graph.facebook.com/v2.0/#{self.fb_id}"
    res = Curl.get(fburl)
    if res.response_code == 200
      fbdata = JSON.parse res.body_str
      self.nickname = fbdata["name"]
      self.picturl = "http://graph.facebook.com/v2.0/#{self.fb_id}/picture?type=large" if self.picturl.nil?
    else
      self.nickname = "FB user #{self.fb_id}"
    end
  end


  def change_into_user! user
    if user.is_a? Fixnum then
      uid = user
    elsif user.is_a? User then
      uid = user.id
    else
      raise DBArgumentError.new "argument not a user", user: user.inspect
    end

    DivesBuddy.transaction do
      self.update_attributes :user_id => uid
      self.users_buddies.each do |bd|
        Notification.create :kind => 'invited_registered', :user_id => bd.user_id, :about => self
        bd.update_attributes :buddy_type => 'User', :buddy_id => uid
      end
      self.dives_buddies.each do |bd|
        Notification.create :kind => 'invited_registered', :user_id => bd.dive.user_id, :about => self unless bd.dive.nil?
        bd.update_attributes :buddy_type => 'User', :buddy_id => uid
      end
      self.signatures.each do |s|
        s.update_attributes :signby_type => 'User', :signby_id => uid
      end
    end
  end

  def nickname
    n = read_attribute(:nickname)
    if n.blank?
      return n ##we need to keep current behavior
    else
      return MiscHelper.nameize(n)
    end
  end

end
