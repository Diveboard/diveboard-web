#require 'composite_primary_keys' # needed to do funky stuff with non-standard primary keys
require 'active_support'
require 'delayed_job'
require_dependency 'password'
require 'validation_helper'
require 'open-uri'


class User < ActiveRecord::Base
  extend FormatApi

  has_many :dives, :class_name => 'Dive'
  has_many :blog_posts
  alias :dive_ids :dife_ids
  has_many :public_dives, :class_name => 'Dive', :conditions => ['privacy = ?', 0], :include => [:spot=>[:region, :location, :country]]
  # AND spots.flag_moderate_private_to_public IS NULL ????
  alias :public_dive_ids :public_dife_ids
  has_many :spots, :through => :dives
  has_many :trips
  ##has_many :public_shops, :class_name => 'Shop', :conditions => ['privacy = ?', 0], :through => :dives, :include => [:shop], :uniq => true
  has_many :public_spots, :through => :public_dives, :source => :spot, :uniq => true
  has_many :auth_tokens, :class_name => 'AuthTokens'
  has_many :user_gears, :order => [:pref_order, :id]
  has_many :payments
  has_many :activity_following, :foreign_key => :follower_id
  has_many :reviews
  has_many :review_votes
  has_many :notifications
  has_many :advertisements, :conditions => {:deleted => false}

  has_many :users_buddies, :uniq => true
  has_many :db_buddies, :source_type => 'User', :through => :users_buddies, :source => :buddy, :uniq => true
  has_many :ext_buddies, :source_type => 'ExternalUser', :through => :users_buddies, :source => :buddy, :uniq => true
  has_many :email_subscriptions, :as => :recipient, :class_name => 'EmailSubscription'
  has_many :user_extra_activities


  has_one :ad_album, :class_name => 'Album', :conditions => ["albums.kind = 'shop_ads'"]
  has_one :cover_album, :class_name => 'Album', :conditions => ["albums.kind = 'shop_cover'"]
  has_one :gallery_album, :class_name => 'Album', :conditions => ["albums.kind = 'shop_gallery'"]
  has_one :wallet_album, :class_name => 'Album', :conditions => ["albums.kind = 'wallet'"]
  has_one :avatar_album, :class_name => 'Album', :conditions => ["albums.kind = 'avatar'"]
  has_many :memberships #group this user is a member of
  has_many :group_memberships, :class_name => 'Membership', :foreign_key => :group_id # users that belong to this group
  has_many :blog_posts
  has_many :newsletter_users, :as => :recipient
  has_many :newsletters, :through => :newsletter_users

  has_many :activities
  has_one :tag

  belongs_to :shop_proxy, :class_name => 'Shop', :foreign_key => :shop_proxy_id
  has_many :baskets
  has_many :fb_likes, :class_name => "FbLike", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id

  has_many :emails_marketing, :as => :target, :class_name => 'EmailMarketing', :source=> :target, :source_type => 'User'

  has_many :treasures

  validates_confirmation_of :password # This automatically validates if :password == :password_confirmation
  validates :admin_rights, :presence => true
  validates_inclusion_of :plugin_debug, :in => %w(DEBUG INFO ERROR), :allow_nil => true

  cattr_accessor :userid  ## this defines the current user context



  after_create :ensure_follow_all!
  after_create :replace_external_users!
  after_update :replace_external_users!
  before_save :ensure_vanity_url
  after_save :reload

  define_format_api :public => [
          :id, :shaken_id, :vanity_url, :qualifications, :picture, :picture_small, :picture_large, :fullpermalink, :permalink, :total_nb_dives, :public_nb_dives, :public_dive_ids, :location, :nickname, :auto_public, full_permalink: ->(u){u.fullpermalink}
        ],
        :private => [ :dan_data, :storage_used, :quota_type, :quota_limit, :all_dive_ids, :pict, :advertisements, :ad_album_id, :user_gears, :total_ext_dives, :db_buddy_ids, :ext_buddy_ids, :about, :lat, :lng, :city, :fb_id, :preferred_locale, :admin_rights],
        :search_light => [ :vanity_url, :about, :stat_longest_dive, :stat_deepest_dive, :public_spot_ids ],
        :search_full => [ :dive_picture_ids ],
        :search_full_server => [:about, :stat_longest_dive, :stat_deepest_dive, :nickname, :permalink, :public_nb_dives, :qualifications, :total_nb_dives, :vanity_url, :id, :picture,
            about_html: lambda {|u| CGI::escapeHTML(u.about).split("\n").join("<br/>")},
            dive_pictures: lambda {|u| Picture.find(u.dive_picture_ids[0..11]).map do |p| p.to_api :public end },
            dives: lambda {|u| u.public_dives.sort do |a,b| b.score <=> a.score end [0..9].map do |d| d.to_api :search_full_server_l1 end}
          ],
        :search_full_server_l1 => [:about, :stat_longest_dive, :stat_deepest_dive, :nickname, :permalink, :public_nb_dives, :qualifications, :total_nb_dives, :vanity_url, :id, :picture,
            about_html: lambda {|u| CGI::escapeHTML(u.about).split("\n").join("<br/>") rescue nil}
          ],
        :search_full_server_l2 => [ :id, :nickname, :vanity_url ],
        :user_with_dives => [
          { :dives_abstract => proc{|u| u.dives.pluck_all(id: 'dives.id', time_in: 'dives.time_in').map do |h| Hash[h.map do |k,v| [k,v.to_s] end] end } }
        ],
        :mobile => [:country_code, :country_name, :trip_names, :units, :all_dive_ids, :admin_rights, :contact_email, :preferred_locale, {
          :wallet_picture_ids => lambda {|u| u.wallet.picture_ids},
          :wallet_pictures => lambda {|u| u.wallet.pictures.map do |p| p.to_api :public end }
        }
        ],
        :pictures => [ :own_pictures ]

  define_api_private_attributes :dan_data, :storage_used, :quota_type, :quota_limit, :all_dive_ids, :dives_abstract, :total_ext_dives, :email, :contact_email, :pict, :trip_names, :units, :auto_public, :admin_rights, :wallet_picture_ids

  define_api_includes :private => [:public], :user_with_dives => [:public], :mobile => [:public], :search_light => [:public], :pictures => [:public], :search_full => [:search_light]

  define_api_updatable_attributes %w( last_name first_name nickname about email contact_email vanity_url location dan_data settings currency total_ext_dives buddies units wallet_picture_ids preferred_locale)
  define_api_updatable_attributes_rec 'dives' => Dive, 'user_gears' => UserGear, 'db_buddies' => User, 'ext_buddies' => ExternalUser
  define_api_requiring_id  %w(dives user_gears buddies db_buddies ext_buddies)
  #password ?  #pict ?  #plugin_debug #fbtoken ?  #quota*

  #Constants
  NO_PICTURE = ROOT_URL+"img/no_picture.png"
  DEFAULT_UNITS = {"distance" => "m", "weight" => "kg", "temperature" => "C", "pressure" => "bar" }


############################
##
## USER MANAGEMENT
##
## !!!!!!!!! WARNING !!!!!!!!!!
##
## TO MAINTAIN EVERYTIME WE ADD/REMOVE RELATIONSHIPS !!!!!
##
############################

  def destroy
    record = self
    ##do all the stuff to ensure that destroy id nicely done
    ##1. create an external user with this user (we still want to keep the relationship)
    e = ExternalUser.create{|u| u.nickname = record.nickname; u.email = record.email; u.fb_id = record.fb_id;}
    ##2. Update the buddyship links
    DivesBuddy.where(:buddy_type => "User", :buddy_id => record.id).each do |b|
      b.buddy_type = "ExternalUser"
      b.buddy_id = e.id
      b.save
    end
    record.dives.destroy_all
    record.auth_tokens.destroy_all
    record.activities.destroy_all ## delete entries from activity feed
    ActivityFollowing.where(:user_id => record.id).destroy_all ## remove all followers
    record.reviews.destroy_all
    record.blog_posts.destroy_all
    record.email_subscriptions.destroy_all
    record.save
    ##erase the user data
    connection.execute("UPDATE `users` SET fb_id = NULL, last_name = NULL, first_name = NULL, email = NULL, vanity_url = NULL, nickname = NULL, location = NULL, settings = NULL, fbtoken = NULL, password = NULL, contact_email = NULL, shop_proxy_id = NULL WHERE id=#{record.id}")
  end

  def merge_into dest_user
    ##this will merge current user assets into dest_user
    connection.execute("UPDATE `activities` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `activity_followings` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `activity_followings` SET follower_id = #{dest_user.id} WHERE follower_id=#{self.id}")
    connection.execute("UPDATE `albums` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `auth_tokens` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `blog_posts` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `dives` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `dives_buddies` SET buddy_id = #{dest_user.id} WHERE buddy_id=#{self.id} AND buddy_type='User'")
    connection.execute("UPDATE `locations` SET verified_user_id = #{dest_user.id} WHERE verified_user_id=#{self.id}")
    connection.execute("UPDATE `notifications` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `payments` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `pictures` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `regions` SET verified_user_id = #{dest_user.id} WHERE verified_user_id=#{self.id}")
    connection.execute("UPDATE `reviews` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `spots` SET verified_user_id = #{dest_user.id} WHERE verified_user_id=#{self.id}")
    connection.execute("UPDATE `spots` SET private_user_id = #{dest_user.id} WHERE private_user_id=#{self.id}")
    connection.execute("UPDATE `trips` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `user_gears` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `users_buddies` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")
    connection.execute("UPDATE `users_buddies` SET buddy_id = #{dest_user.id} WHERE buddy_id=#{self.id} AND buddy_type LIKE 'User'")
    connection.execute("UPDATE `wikis` SET user_id = #{dest_user.id} WHERE user_id=#{self.id}")

    
    dest_user.fb_id = self.fb_id if !self.fb_id.nil? && dest_user.fb_id.nil?
    dest_user.fbtoken = self.fbtoken if !self.fbtoken.nil? && dest_user.fbtoken.nil?
    dest_user.email = self.email if !self.email.nil? && dest_user.email.nil?
    dest_user.contact_email = self.contact_email if !self.contact_email.nil? && dest_user.contact_email.nil?
    dest_user.password = self.password if !self.password.nil? && dest_user.password.nil?
    dest_user.location = self.location if !self.location.nil? && dest_user.location.nil?
    dest_user.last_name = self.last_name if !self.last_name.nil? && dest_user.last_name.nil?
    dest_user.first_name = self.first_name if !self.first_name.nil? && dest_user.first_name.nil?
    dest_user.save


    self.destroy
  end

############################
##
## END OF USER MANAGEMENT
##
############################


  def is_private_for?(options={})
    return true if options[:private]
    return true if options[:caller] == self
    return true if options[:caller] && Membership.where({:user_id => options[:caller].id, :group_id => self.id, :role => 'admin'}).count > 0
    Rails.logger.debug "Caller has admin rights #{options[:caller].admin_rights rescue "none"}"
    return true if options[:caller].admin_rights == 5 rescue nil #5 is for super duper admin
    return false
  end


  # Checks login information
  def self.authenticate(email, pass)
    user = User.find(:first, :conditions => ['email = ?',email])
    if user.nil?
      return false
    end
    if user.password.nil? || user.password.empty?
      return false
    end

    if Password::check(pass,user.password)
      return user
    else
      return false
    end
  end

  def self.random_cool_logbook
    (User.select("distinct(users.id)").joins(', dives, pictures').where("pictures.user_id = users.id and dives.user_id = users.id and users.about != '' and dives.privacy=0").sort_by{rand}).last.reload
  end


######
###### Validators on setters
######


  def email=(val)
    ValidationHelper.check_email_format(val) unless val.nil?
    u = User.find_by_email(val)
    raise DBArgumentError.new "Already taken" unless (u.nil? || u.id == self.id) || val.nil?
    write_attribute(:email, val)
    #write_attribute(:contact_email, val) #if we have an email it's also the contact email
  end


  def fbtoken=(val)
    write_attribute(:fbtoken, val)
    make_fb_token_long_lived
    update_fb_permissions
  end

  def contact_email=(val)
    ValidationHelper.check_email_format(val) unless val.nil?
    write_attribute(:contact_email, val)
  end

  def contact_email
    ## if a user has a login email it's his contatc
    return email unless email.nil?
    read_attribute(:contact_email)
  end

  def vanity_url=(val)
    return val if val == read_attribute(:vanity_url)
    ValidationHelper.vanity_url_checker(val)
    u = User.find_by_vanity_url(val)
    raise DBArgumentError.new "Already taken" unless (u.nil? || u.id == self.id)
    write_attribute(:vanity_url, val)
  end

  def location=(val)
    if val.nil? then
      write_attribute(:location, nil)
    else
      c = ::Country.where(:ccode => val.upcase)
      if !val.nil? && c.count > 0 then
        write_attribute(:location, val.downcase)
      else
        raise DBArgumentError.new "location for user is not valid", location: val
      end
    end
  end

  def settings=(val)
    if val.nil? || val.class.to_s == 'String' then
      write_attribute(:settings, val)
    else
      write_attribute(:settings, val.to_json)
    end
    begin
      write_attribute(:privacy, self.sci_privacy)
    rescue
      write_attribute(:privacy, 0)
    end
  end

  def settings
    return '{}' if read_attribute(:settings).nil?
    read_attribute(:settings)
  end

  #def dives=(dive_list)
  #end

 def nickname
   n = read_attribute(:nickname)
   if n.blank?
     return "nickname"
   else
     return MiscHelper.nameize(n)
   end
 end


#######
####### Access to preferences in JSON
#######


  def full_name
    fullname = ""
    if !first_name.nil? then
      fullname += "#{first_name.titleize}"
      end
    if !first_name.nil? then
      if fullname !="" then
        fullname += " "
      end
      fullname += "#{last_name.titleize}"
    end
    if fullname =="" then
      fullname = nickname
    end

    return fullname

  end


  def qualifications
    qualifs = JSON.parse(self.settings)["qualifs"] rescue nil
    noqualifs = {}
    if qualifs.nil?
      return noqualifs
    else
      ## TODO : need to ensure that dates are really dates and that to_date won't throw an exception...
      return qualifs
    end
  end

  def auto_fb_share check_perms=false
    #users wants to post to wall by default
    share = JSON.parse(self.settings)["auto_fb_share"] rescue nil
    if share.nil?
      return false
    else
      if check_perms==true
        return (share && (fb_permissions_granted("publish_stream")==true))
      else
        return share
      end
    end
  end

  def auto_public
    #users wants to post to wall by default
    share = JSON.parse(self.settings)["auto_public"] rescue nil
    if share.nil?
      return true
    else
      return share
    end
  end

  def share_details_notes
    #Dive logbook notes visibility
    share = JSON.parse(self.settings)["share_details_notes"] rescue nil
    if share.nil?
      return true
    else
      return share
    end
  end

  def units=val
    a=val.dup
    a['distance'] = 'm' if a['distance']=~ /km/i
    a['weight'] = 'kg' if a['distance']=~ /kg/i
    preferred_units = a
  end

  def units
    a=preferred_units.dup
    a['distance'] = 'm' if a['distance']=~ /km/i
    a['weight'] = 'Kg' if a['distance']=~ /kg/i
    return a
  end

  def preferred_units
    pref = JSON.parse(self.settings)["units"] rescue {}
    pref ||= {}
    pref['distance'] = 'm' if pref['distance']=~ /km/i
    pref['weight'] = 'Kg' if pref['distance']=~ /kg/i
    DEFAULT_UNITS.merge pref
  end

  def preferred_units=val
    pref = units
    pref.merge! val
    current_settings = JSON.parse(self.settings) rescue {}
    current_settings['units'] = pref
    self.settings = current_settings
  end


  def unitSI?
    if self.preferred_units["distance"] == "m"
      return true
    else
      return false
    end
  end

  def accept_instant_notif_email?
    accept_instant_notif_email.nil? || accept_instant_notif_email
  end

  def accept_weekly_notif_email?
    accept_weekly_notif_email.nil? || accept_weekly_notif_email
  end

  def accept_weekly_digest_email?
    accept_weekly_digest_email.nil? || accept_weekly_digest_email
  end

  def accept_newsletter_email?
    accept_newsletter_email.nil? || accept_newsletter_email
  end

  def sci_privacy
    #users wants to post to wall by default
    sci_privacy = JSON.parse(self.settings)["sci_privacy"] rescue nil
    if sci_privacy.nil?
      return 1
    else
      return sci_privacy.to_i
    end
  end


#######
####### End of access to preferences in JSON
#######

  def location
    read_attribute(:location) || 'blank'
  end

  def country
    Country.where(:ccode => self.location.upcase).first
  end

  def country_code
    return nil if location == 'blank'
    location.upcase
  end

  def country_name
    c=country
    return nil if c.nil? || c.id == 1
    c.name
  end

  def avatars
    avatar_album || Album.create(:user_id => self.id, :kind => 'avatar')
  end

  def crop_picture=(img_hash)
    img = {}
    img_hash.each do |key, val|
      img[key.to_sym] = val
    end

    if img[:selected_pic].to_i == 1 then
      logger.debug "updating picture for user #{self.id} with #{img} >>> #{img[:selected_pic]}"
      raise DBArgumentError.new 'crop_pictname must be provided' if img[:crop_pictname].blank?

      logger.debug "using image "+img[:crop_pictname].gsub('/','')
      image = MiniMagick::Image.open("public/tmp_upload/"+img[:crop_pictname].gsub('/','')) rescue raise(DBArgumentError.new "Impossible to open file", file: img[:crop_pictname].gsub('/',''), msg: $!.message)

      logger.debug "cropping #{img[:crop_coords_w].to_i}x#{img[:crop_coords_w].to_i}+#{img[:crop_coords_x].to_i}+#{img[:crop_coords_y].to_i}"
      image.crop "#{img[:crop_coords_w].to_i}x#{img[:crop_coords_w].to_i}+#{img[:crop_coords_x].to_i}+#{img[:crop_coords_y].to_i}"

      factor =  ((1000000 / img[:crop_coords_w].to_i)/100).to_f
      logger.debug "resizing #{factor.to_s}%"
      image.resize "#{factor.to_s}%"
      #end
      image.format "png"
      avatar_path = "public/user_images/#{self.id}.png"
      image.write avatar_path
      logger.debug "Image saved"
      self.pict = true
      self.picture_source == "upload"

      new_avatar = Picture.create_image({:path => avatar_path, :user_id => self.id})
      new_avatar.append_to_album self.avatars.id

    elsif !img[:picture_id].blank? && !Picture.find_by_id(img[:picture_id].to_i).nil? then
      logger.debug "updating picture for user #{self.id} with #{img} >>> #{img[:picture_id]}"
      require 'open-uri'
      p = Picture.find_by_id(img[:picture_id].to_i)
      begin
        image = MiniMagick::Image.open(p.original_image_path)
      rescue
        image = MiniMagick::Image.open(p.original)
      end
      image.write "public/user_images/#{self.id}.png"
      logger.debug "Image saved"
      self.pict = true
      p.append_to_album self.avatars.id
    else
      logger.debug "Using standard picture"
      self.pict = false
    end

  end

  def crop_picture
    nil
  end

  def fb_picture
    "//graph.facebook.com/v2.0/#{fb_id}/picture?width=200&height=200"
  end

  def fb_picture_small
    return "//graph.facebook.com/v2.0/#{fb_id}/picture?width=100&height=100"
  end

  def picture
    #if pict == 0 => FB image
    if !self.pict
      if self.fb_id.nil?
        return NO_PICTURE
      else
        return "//graph.facebook.com/v2.0/#{fb_id}/picture?width=200&height=200"
      end
    else
      begin
        self.avatars.pictures.last.thumb
      rescue
        return HtmlHelper.lbroot("/user_images/"+self.id.to_s+".png")
      end
    end
  end

  def picture_small
    ## square picture which can be scaled down
     #if pict == 0 => FB image
     if !self.pict
       if self.fb_id.nil?
          return NO_PICTURE
        else
          return "//graph.facebook.com/v2.0/#{fb_id}/picture?width=100&height=100"
        end
     else
      begin
        self.avatars.pictures.last.thumb
      rescue
        return HtmlHelper.lbroot("/user_images/"+self.id.to_s+".png")
      end
     end
   end

  def picture_large
    if !self.pict
      if self.fb_id.nil?
        return NO_PICTURE
      else
        return "//graph.facebook.com/v2.0/#{fb_id}/picture?width=200&height=200"
      end
    else
      begin
        self.avatars.pictures.last.large
      rescue
        return HtmlHelper.lbroot("/user_images/"+self.id.to_s+".png")
      end
    end
  end

  def picture_medium
    if !self.pict
      if self.fb_id.nil?
        return NO_PICTURE
      else
        return "//graph.facebook.com/v2.0/#{fb_id}/picture?width=200&height=200"
      end
    else
      begin
        self.avatars.pictures.last.medium
      rescue
        return HtmlHelper.lbroot("/user_images/"+self.id.to_s+".png")
      end
    end
  end

  def has_picture?
    return true if self.pict || self.fb_id
  end

  def dived_location_list
    return @attributes_cache['dived_location_list'] unless @attributes_cache['dived_location_list'].nil?
    dived_location=""
    #returns an array of dive one dive per location
    self.dives.where("spot_id <> 1").where(:privacy => 0).includes({:spot => :country}).joins(:spot).group("country_id").each do |uniquedive|
           spot_cname = uniquedive.spot.country.cname rescue nil
           next if spot_cname.nil?
           if !dived_location.empty? then dived_location +=", " end
           dived_location += spot_cname
         end
    @attributes_cache['dived_location_list'] = dived_location
    return dived_location
  end

  def ordered_dives
    Dive.unscoped.joins("left join dives d2 on dives.trip_id = d2.trip_id and dives.user_id = d2.user_id").where(:user_id => self.id).group('dives.id').order('ifnull(max(d2.time_in), dives.time_in) DESC, dives.trip_id, dives.time_in DESC').includes([:user, :trip, :spot => [:country, :location, :region]])
  end

  def all_dive_ids
    dives.map(&:id)
  end

  def latest_full_dive
    dives.where("spot_id <> 1").limit(1)
  end

  def full_public_dives
    dives.where("privacy = 0 AND spot_id <> 1").includes([:user, :spot => [:country, :location, :region]])
  end

  def draft_dives
    dives.where("spot_id = 1").includes([:user, :spot => [:country, :location, :region]])
  end

  def full_dives
    dives.where("spot_id <> 1").includes([:user, :spot => [:country, :location, :region]])
  end

  def favorite_dives
    dives.where("privacy = 0 AND spot_id <> 1 AND favorite = true").includes([:user, :spot => [:country, :location, :region]])
  end

  def longest_dive
    return full_public_dives.reorder('duration DESC').limit(1).first
  end

  def deepest_dive
    begin
      #return full_public_dives.reorder('maxdepth DESC').limit(1).first
      deep_m =full_public_dives.where("maxdepth_unit = 'm'").reorder('maxdepth_value DESC').limit(1).first
      deep_ft =full_public_dives.where("maxdepth_unit = 'ft'").reorder('maxdepth_value DESC').limit(1).first
      # we rescue -1 since some ppl have depth = 0...
      return (begin deep_m.maxdepth rescue -1 end > begin deep_ft.maxdepth rescue -1 end)?deep_m:deep_ft
    rescue
      nil
    end
  end

  def stat_deepest_dive
    #return full_public_dives.reorder('maxdepth DESC').limit(1).pluck(:maxdepth).first
    return begin deepest_dive.maxdepth.to_f rescue nil end
  end

  def stat_longest_dive
    return full_public_dives.reorder('duration DESC').limit(1).pluck(:duration).first
  end

  def underwater_time
    if dives == nil then
        return 0
    else
        total_duration = 0
        dives.each do |dive|
          if (dive.duration != nil) then
            total_duration += dive.duration
          end
        end
        return total_duration
    end
  end

  def region_most_dived
    begin
      region_count = full_public_dives.joins(:spot).group('spots.country_id').count
      region_count.delete 1
      max_number = region_count.values.max
      region_count.each{|r,n|
        if n == max_number then
          return Country.find(r).cname
        end
      }
    end
    return nil
  end

  def total_nb_dives
    self.total_ext_dives + dive_ids.count
  end

  def public_nb_dives
    return public_dives.to_ary.count if public_dives.loaded?
    return public_dives.count
  end

  def full_public_dives_with_picture
    begin
      return full_public_dives.from('dives, picture_album_pictures j').where('dives.album_id = j.picture_album_id').group('dives.id')
    end
    return []
  end

  def trip_names
    trips.map(&:name).sort
  end

  def lastmod
    #last modifications on user's logbook
    Date.today.to_date

  end

  def export_all_in_ZXL
    d = Divelog.new
    d.fromDiveDB(Dive.where("user_id = ?", self.id).map{|dive| dive.id})
    d.toZXL
  end

  def export_in_ZXL(dive_list)
    d = Divelog.new
    d.fromDiveDB(dive_list)
    d.toZXL
  end


  def update_fb_permissions
    if !self.fbtoken.blank?  #https://graph.facebook.com/me/permissions?access_token=126856984043229|9d0ca5314708629221df5d67.1-680251975|4ETlwWq5hdgqiGj3JRIQ-Ll0klY
      # returns false for error, true for success
      uri = URI.parse(URI.escape("https://graph.facebook.com/v2.0/me/permissions?access_token=#{self.fbtoken}"))
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
        response = http.request(request)
        data = response.body
        logger.debug "Got : #{data}"
        if !JSON.parse(data)["error"].nil?
          self.fb_permissions = nil
          self.fbtoken = nil
          self.save
          return false
        end
        if JSON.parse(data)["data"][0] != "null"
          self.fb_permissions = (JSON.parse(data)["data"][0]).to_json
        else
          ## NO permissions have been granted
          self.fb_permissions = ""
        end
        self.save
        return true
      rescue
        logger.debug "Error #{$!.message}"
        logger.debug $!.backtrace
        ## if FB API fails, let's consider no perissions have been granted - anyways you won't be able to do much....
        self.fb_permissions = ""
        self.save
        return false
      end
    else
      self.fb_permissions = nil
      self.save
    end
  end
  handle_asynchronously :update_fb_permissions

  def fb_permissions_granted permission=nil

   ### WILL Return the JSON RESPONSE if no argument
   ### true or false if argument passed beign the permission to be checked
   ### permissions can me a list separated by a ","
   ### return of nil means token is INVALID or NON-EXISTANT


    ## currently Koala does not support this, so we'll need to build up the request url manuall and process it


    ## fb_Permissions are set to nil whenever we re-log a user (from cookie or from FB, i.e. one per session)
    if fb_permissions.nil? && !self.fbtoken.nil? then
      update_fb_permissions unless @will_update_fb_permissions
      @will_update_fb_permissions = true
      return false
    end

    if fbtoken == nil
      ## may have been nilled by update_fb_permissions
      return nil
    else
      if permission.nil?
        return fb_permissions
      else
        begin
          decodedata = JSON.parse(fb_permissions)
          permission.gsub(/\ /, "").split(",").each do |perm|
            if decodedata[perm] != 1
              return false
            end
          end
          return true
        rescue
          ## decoding failed, let's remove the messy string then
          logger.debug "Deleting FB permission string "+ (fb_permissions || "null") + " which could not be decoded"
          self.fb_permissions = nil
          self.save
          return false
        end
      end
    end
  end

  # Get the friends of the person, and checks which is already a diveboarder
  def fb_friends
    if fb_id.nil? then return nil end

    if !self.fbtoken.nil? && !self.fbtoken.empty?
      url_to_call = "https://graph.facebook.com/v2.0/me/friends?limit=500&access_token=#{self.fbtoken}"
      all_data = []
      begin
      while !url_to_call.nil? do
        uri = URI.parse(URI.escape(url_to_call))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
          response = http.request(request)
          json_data = response.body
          logger.debug "Got : #{json_data}"
          data = JSON.parse(json_data)
          if !data["error"].nil?
            return nil
          end

          data["data"].each{|friend|
            friend["diveboard"] = User.where(:fb_id => friend["id"])
          }

          all_data.concat(data["data"])
          url_to_call = data["paging"] && data["paging"]["next"] || nil
        end

        return all_data
      rescue
        ## if FB API fails, let's consider no perissions have been granted - anyways you won't be able to do much....
        return nil
      end
    else
      return nil
    end

  end

  def make_fb_token_long_lived
    if !fbtoken.blank?
      logger.debug "Making FB token long lived : #{fbtoken}"
      url_to_call = "https://graph.facebook.com/v2.0/oauth/access_token?client_id=#{FB_APP_ID}&client_secret=#{FB_APP_SECRET}&grant_type=fb_exchange_token&fb_exchange_token=#{self.fbtoken}"
      begin
        uri = URI.parse(URI.escape(url_to_call))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
        response = http.request(request)
        response_txt = response.body
        Rails.logger.debug "FB token extended : "+response_txt
        data = CGI.parse(response_txt)
        old_fbtoken = fbtoken
        Rails.logger.debug "New fbtoken should be #{data['access_token'].first}"
        write_attribute :fbtoken, data['access_token'].first
        save!
        new_fbtoken = User.find(self.id).fbtoken
        Rails.logger.debug "Exchanged fbtoken from #{old_fbtoken} to #{new_fbtoken}"
      rescue
        logger.debug "Failed to extend permissions for FB token #{$!.message}"
      end
    end
  end
  handle_asynchronously :make_fb_token_long_lived

  def check_valid_fbtoken
    return false if self.fbtoken.nil?
    logger.debug "Checking the user fbtoken #{self.fbtoken} if valid"
    graph = Koala::Facebook::API.new fbtoken
    begin
      graph.get_object("me")
      logger.debug "token validation OK"
      return true
    rescue
      self.fbtoken = nil
      self.fb_permissions = nil
      self.save
      self.reload
      logger.debug "FB token was not valid - we deleted it #{$!.message}"
      return false
    end
  end

  def dan_data
    return JSON.parse(read_attribute(:dan_data)) unless read_attribute(:dan_data).nil?
  end

  def dan_data=(v)
    if v.nil? then
      write_attribute(:dan_data, nil)
    else
      write_attribute(:dan_data, v.to_json)
    end
  end

  def pictures
    (own_pictures|dive_pictures).uniq
  end

  def dive_pictures
    Picture.select('distinct pictures.*').joins('JOIN picture_album_pictures, dives, users').where('(picture_album_pictures.picture_id = pictures.id and picture_album_pictures.picture_album_id = dives.album_id and dives.user_id = users.id and users.id = :uid)', {:uid => self.id}).to_ary
  end

  def dive_picture_count
    ActiveRecord::Base.connection.select_value("SELECT count(distinct picture_album_pictures.picture_id) FROM picture_album_pictures, dives WHERE picture_album_pictures.picture_album_id = dives.album_id and dives.user_id = #{self.id}")
  end

  def dive_picture_ids
    ActiveRecord::Base.connection.select_values("SELECT distinct picture_album_pictures.picture_id FROM picture_album_pictures, dives WHERE picture_album_pictures.picture_album_id = dives.album_id and dives.user_id = #{self.id}")
  end

  def own_pictures
    Picture.select('distinct pictures.*').where(:user_id => self.id).includes([:cloud_thumb, :cloud_large, :cloud_small, :cloud_medium, :cloud_original_video, :cloud_original_image]).sort{|a,b| b.created_at<=>a.created_at}
  end

  def storage_used
    raw = connection.select_one "select SUM(CASE dived when 0 then 0 else size END) dive_pictures,
      SUM(CASE when dived > 0 AND  DATE_ADD(created_at, INTERVAL 1 MONTH) >= NOW() then size else 0 END) monthly_dive_pictures,
      SUM(CASE dived when 0 then size else 0 END) orphan_pictures,
      SUM(size) all_pictures
      FROM (SELECT pictures.id, pictures.user_id, count(dives.id) dived, pictures.created_at, pictures.size FROM pictures
      left join picture_album_pictures on pictures.id = picture_album_pictures.picture_id
      left join dives on  picture_album_pictures.picture_album_id = dives.album_id
      where (dives.user_id = #{self.id} OR dives.id is null) and pictures.user_id = #{self.id}
      GROUP BY picture_album_pictures.picture_id) pics"
    result = {}
    raw.each do |key, val|
      result[key.to_sym] = val.to_i
    end
    return result
  end

  def last_storage_payment
    Payment.where(:category => 'storage', :user_id => self.id, :status => ['awaiting', 'confirmed']).where('validity_date <= curdate() AND (curdate()-validity_date)<storage_duration').order('validity_date, created_at DESC').limit(1).first
  end

  def update_quota!
    pay = last_storage_payment
    if pay.nil? then
      self.quota_type = 'per_month'
      self.quota_limit = Rails.application.config.default_storage_per_month
      self.quota_expire = nil
    else
      self.quota_type = 'per_user'
      self.quota_limit = pay.storage_limit
      self.quota_expire = pay.validity_date.to_time + pay.storage_duration
    end
    logger.debug "Updating quotas for user #{self.id}  with payment '#{pay.nil? || pay.id}' : #{self.quota_type} - #{self.quota_limit} - #{self.quota_expire}"
    self.save!
    logger.debug "quota update done for user #{self.id}"
    self
  end

  def can_subscribe plan_id
    logger.debug "Check of subscription for #{self.id} plan:#{plan_id} >>> #{Rails.application.config.storage_plans[plan_id]}"
    return false if Rails.application.config.storage_plans[plan_id].nil?
    pay = last_storage_payment
    return (pay.nil? || pay.confirmed?) && Rails.application.config.storage_plans[plan_id][:quota] > self.quota_limit
  end

  def available_discount
    total_discount = 0

    #Actually this algorithm is not correct in the case of multiple upgrades during the same year : the 'usage' of money should depend on storage size allowed
    Payment.where(:category => 'storage', :user_id => self.id, :status => ['awaiting', 'confirmed']).where('validity_date <= curdate() AND (curdate()-validity_date)<storage_duration').order('validity_date DESC').each do |pay|
      left = pay.storage_duration-(Time.now - pay.validity_date.to_time)
      logger.debug "time left on subscription #{pay.id} : #{left}"
      discount = pay.amount*left/pay.storage_duration
      logger.debug "discount calculated for #{pay.id} : #{discount}"
      next if discount > pay.amount
      next if discount <= 0
      total_discount += discount
    end

    total_discount = total_discount.round(2).to_f

    #Just to be sure we're not saying anything too stupid
    return if total_discount <= 0
    return total_discount
  end

  def available_storage_plans
    plans = {}
    pay = last_storage_payment
    return if !pay.nil? && !pay.confirmed?
    discount = available_discount || 0
    Rails.application.config.storage_plans.each do |plan_name, plan|
      logger.debug "#{plan[:quota]} #{self.quota_limit}"
      next if plan[:quota] <= self.quota_limit
      plans[plan_name] = plan
      plans[plan_name][:price] = [(plans[plan_name][:cost] - discount).round(2).to_f, 0].max
    end
    return if plans.count == 0
    return plans
  end

  def activity_feed
    return ActivityFeed::for_user(self.id)
  end


  def update_follow_from_facebook
    begin
      return if self.fb_id.nil? || self.fbtoken.blank?

      url = "https://graph.facebook.com/v2.0/me/friends?access_token=#{self.fbtoken}"
      uri = URI.parse(URI.escape(url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      #friends are paginated
      while !url.nil? do
        #make request to facebook
        uri = URI.parse(url)
        request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
        response = http.request(request)
        data_json = response.body
        logger.debug "Friends from Facebook: #{data_json}"
        data = JSON.parse(data_json)
        return false if !data["error"].nil?

        #get all the fb_ids of the friends
        searched_friends = []
        data['data'].each do |friend|
            searched_friends.push(friend['id'].to_i) rescue -1
        end

        #find all the users we know on diveboard that are not already followed (or excluded)
        missing_friends = User.joins("LEFT JOIN activity_followings ON follower_id = #{self.id} AND tag is NULL and dive_id is null and spot_id is null and location_id is null and region_id is null and country_id IS NULL and shop_id is null and picture_id is null and user_id = users.id").where(:fb_id => searched_friends).where('activity_followings.id IS NULL')

        missing_friends.each do |db_friend|
          begin
            ActivityFollowing.create  :follower_id => self.id, :user_id => db_friend.id
            Rails.logger.debug "user #{self.id} now follows #{db_friend.id}"
          rescue
          end
        end

        url = data["paging"]['next'] rescue nil
      end

      return true
    rescue
      api_exception $!
      return false
    end
  end


  def follow?(what)
    begin
      where = what.dup
      where[:follower_id] = self.id
      where[:user_id] = nil unless where.include? :user_id
      where[:dive_id] = nil unless where.include? :dive_id
      where[:spot_id] = nil unless where.include? :spot_id
      where[:location_id] = nil unless where.include? :location_id
      where[:region_id] = nil unless where.include? :region_id
      where[:country_id] = nil unless where.include? :country_id
      where[:shop_id] = nil unless where.include? :shop_id
      where[:picture_id] = nil unless where.include? :picture_id
      where[:exclude] = false
      return ActivityFollowing.where(where).count > 0
    rescue
      api_exception $!
      return false
    end
  end

  def follow_all?
    follow?({})
  end

  def following_includes
    begin
      topics = []
      self.activity_following.each do |f|
        next if f.exclude
        topics.push(User.find(f.user_id))  rescue nil
        topics.push(Dive.find(f.dive_id))  rescue nil
        topics.push(Spot.find(f.spot_id))  rescue nil
        topics.push(Location.find(f.location_id))  rescue nil
        topics.push(Region.find(f.region_id))  rescue nil
        topics.push(Country.find(f.country_id))  rescue nil
        topics.push(Shop.find(f.shop_id))  rescue nil
        topics.push(Picture.find(f.picture_id))  rescue nil
      end
      return topics
    rescue
      api_exception $!
      return false
    end
  end

  def following_excludes
    begin
      topics = []
      ActivityFollowing.where(:follower_id => self.id).includes([:user, :dive, :spot, :location, :region, :country, :shop, :picture]).each do |f|
        next unless f.exclude
        topics.push(User.find(f.user_id))  rescue nil
        topics.push(Dive.find(f.user_id))  rescue nil
        topics.push(Spot.find(f.spid_id))  rescue nil
        topics.push(Location.find(f.location_id))  rescue nil
        topics.push(Region.find(f.region_id))  rescue nil
        topics.push(Country.find(f.country_id))  rescue nil
        topics.push(Shop.find(f.shop_id))  rescue nil
        topics.push(Picture.find(f.picture_id))  rescue nil
      end
      return topics
    rescue
      api_exception $!
      return false
    end
  end

  def following_suggest(what)
    list = []
    if what == 'shop_id' then
      list += Shop.joins(:dives).joins("left join activity_followings on activity_followings.shop_id = shops.id and activity_followings.follower_id=#{self.id}").where('dives.user_id' => self.id, 'activity_followings.id' => nil).group('shops.id').limit(5)
    elsif what == 'country_id' then
      my_country = self.country
      list.push self.country unless my_country.nil? || my_country.id == 1 || follow?(:country_id => my_country.id)
      list += Country.joins(:dives).joins("left join activity_followings on activity_followings.country_id = countries.id and activity_followings.follower_id=#{self.id}").where('dives.user_id' => self.id, 'activity_followings.id' => nil).where('countries.id != 1').group('countries.id').order('count(dives.id) DESC').limit(5)
    elsif what == 'spot_id' then
      list += Spot.joins(:dives).joins("left join activity_followings on activity_followings.spot_id = spots.id and activity_followings.follower_id=#{self.id}").where('dives.user_id' => self.id, 'activity_followings.id' => nil).where('spots.id != 1').having('count(dives.id) > 7').group('spots.id').order('count(dives.id) DESC').limit(5)
    end
    return list.uniq
  end

  def ensure_follow_all!
    return if self.is_group?
    ActivityFollowing.create({:follower_id => self.id, :exclude => false}) unless self.follow_all?
  end

  def review_for_shop(shop)
    if shop.is_a? Shop then
      self.reviews.where(:shop_id => shop.id).first
    else
      self.reviews.where(:shop_id => shop).first
    end
  end

  def can_edit?(object)
    return true if self.admin_rights >= 5
    return object.is_private_for?({:caller => self}) if object.respond_to?(:is_private_for?)
    return true if object.is_a?(User) && self.id == object.id
    return true if object.is_a?(Shop) && self.shop_proxy_id == object.id
    return false
  end

  def can_sudo?
    begin
      return true if Membership.where({:user_id => self.id, :role => 'admin'}).count > 0
      return true if admin_rights >= 4
    rescue
    end
    return false
  end

  def is_group?
    return !shop_proxy.nil?
  end

  def has_admin?
    Membership.where(:group_id => self.id, :role => 'admin').count > 0
  end

  def shops_owned
    Membership.where(:user_id => self.id, :role => 'admin').includes(:group => :shop_proxy).where('users.shop_proxy_id is not null').map do |m| m.group.shop_proxy end
  end

  def permalink
    if vanity_url.blank?
      "/"
    elsif shop_proxy_id.nil?
      "/#{vanity_url}"
    else
      "/pro/#{vanity_url}"
    end

  end
  def fullpermalink option=nil
    option = preferred_locale if option == :preferred
    HtmlHelper.find_root_for(option).chop + permalink
  end

  def shaken_id
    "U#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "U"
      return Mp.deshake(code[1..-1])
    elsif code.to_i == 0 then
      return nil
    else
      return code.to_i
    end
  end

  def generate_vanity
    if !self.vanity_url.blank?
      return true
    end
    if !self.nickname.blank?
      basename = self.nickname.to_url
    elsif !self.first_name.blank? || !self.last_name.blank?
      basename = "#{self.first_name} #{self.last_name}".to_url
    else
      return false
    end
    if User.find_by_vanity_url(basename).blank?
      self.vanity_url = basename
      self.save
    else
      i=0
      until User.find_by_vanity_url("#{basename}-#{i}").empty?
        i = i+1
      end
      self.vanity_url = "#{basename}-#{i}"
      self.save
    end
  end

  def create_shop_vanity!
    vanity_prefix = self.shop_proxy.name.gsub(/_(ltd|lda|sl|inc|gmbh|srl|snc|sas)/, '').to_url
    vanity_prefix = 'dive_center' if vanity_prefix.blank?
    vanity_prefix = "dive_center_#{vanity_prefix}".to_url if vanity_prefix.length < 3
    vanity_counter = 1
    new_vanity=vanity_prefix
    while User.where(:vanity_url => new_vanity).count > 0 do
      new_vanity = "#{vanity_prefix}_#{vanity_counter}"
      vanity_counter+=1
    end
    self.vanity_url = new_vanity
  end

  def ad_album_id
    ad_album.id rescue Album.create(:user_id => self.id, :kind => 'shop_ads').id
  end

  def cover_album_id
    cover_album.id rescue Album.create(:user_id => self.id, :kind => 'shop_cover').id
  end

  def gallery_album_id
    gallery_album.id rescue Album.create(:user_id => self.id, :kind => 'shop_gallery').id
  end

  def wallet
    wallet_album || Album.create(:user_id => self.id, :kind => 'wallet')
  end

  def wallet_picture_ids=(val)
    ## add pics to wallet album
    if val.is_a? String
      val = JSON.parse(val)
    end
    raise DBArgumentError.new "wallet_picturs_id must be an array" unless val.is_a? Array
    val.each do |e|
      raise DBArgumentError.new "wallet_picturs_id content must be ints" unless e.is_a? Integer
    end
    if !(wp = self.wallet.pictures).empty?
      self.wallet.empty!
    end
    wrong_id = []
    wallet_album_id = self.wallet.id
    val.each do |p|
      begin
        Picture.find(p).append_to_album(wallet_album_id)
      rescue
        Rails.logger.debug $!.message
        wrong_id << p
      end
    end
    raise DBArgumentError.new "could not add pictures  #{wrong_id.to_s}" unless wrong_id.empty?
  end

  def public_shops
    self.dives.reject do |d| d.privacy>0 || d.shop_id.nil? end .map(&:shop).uniq.reject(&:nil?)
  end

  def all_shops
    self.dives.reject do |d| d.shop_id.nil? end .map(&:shop).uniq.reject(&:nil?)
  end

  def ext_buddy_ids #activerecord mixes all ids together....
    self.ext_buddies.map &:id
  end

  def db_buddy_ids #activerecord mixes all ids together....
    self.db_buddies.map &:id
  end

  def buddies
    r=[]
    r += self.db_buddies
    r += self.ext_buddies
    return r
  end

  def buddies_sorted
    common_dives = Media::select_all_sanitized("select buddy_type, buddy_id, count(*) c
      from dives, dives_buddies
      where dives.user_id = :user_id and dives.id = dives_buddies.dive_id
      group by buddy_type, buddy_id",
      {:user_id => self.id})

    ranks = {}
    common_dives.each do |h|
      ranks["#{h['buddy_type']} #{h['buddy_id']}"] = h['c']
    end

    buddies.sort! do |b,a|
      (ranks["#{a.class.name} #{a.id}"] <=> ranks["#{b.class.name} #{b.id}"]) || 0
    end

  end

  def buddies=args
    args = JSON.parse(args) if String === args

    invited_buddies = []
    new_db_buddies = []
    new_ext_buddies = []
    args.each do |bud|
      if bud['db_id'].blank? then
        u = ExternalUser.find_or_create self, bud
        if ExternalUser === u then
          new_ext_buddies.push(u)
          invited_buddies.push(u) if bud['invited']
        elsif User === u then
          new_db_buddies.push(u)
        end
      else
        new_db_buddies.push(User.find bud['db_id'])
      end
    end

    self.db_buddies = new_db_buddies
    self.ext_buddies = new_ext_buddies

    #marking as invited the ones that were flagged
    self.users_buddies.where(:buddy_type => 'ExternalUser', :buddy_id => invited_buddies.map(&:id)).each do |link|
      link.invited_at = Time.now
      link.save
    end
  end

  def currency
    currency = read_attribute(:currency)
    return currency || 'USD'
  end
  def currency=(val)
    raise DBArgumentError.new "Currency is not valid", currency: val unless Money::Currency.available.map do |c| c[:iso_code] end .include?(val) || val.nil?
    write_attribute(:currency, val)
  end
  def currency?
    !read_attribute(:currency).nil?
  end
  def currency_symbol
    Money::Currency.find(currency).symbol rescue nil
  end

  def currency_first
    Money::Currency.find(currency).symbol_first rescue true
  end

  def my_species
    ##will find all the species seen by a user
    #dives = connection.execute("SELECT `id` FROM `dives` WHERE `user_id` = #{self.id}").map{|e| e[0]}
    #SNAMES
    #SELECT DISTINCT(`sname_id`) FROM `dives_eolcnames` INNER JOIN `dives` ON `dives`.`id` = `dives_eolcnames`.`dive_id` WHERE `dives`.`user_id` = 30 AND `sname_id` IS NOT NULL;
    #SNAMES from CNAMES
    #SELECT DISTINCT(`eolsname_id`) FROM `eolcnames` INNER JOIN `dives_eolcnames` ON `eolcnames`.`id` = `dives_eolcnames`.`cname_id` INNER JOIN `dives` ON `dives`.`id` = `dives_eolcnames`.`dive_id` WHERE `dives`.`user_id` = 30 AND `eolsname_id` IS NOT NULL;
    species = connection.select_values("SELECT DISTINCT(`sname_id`)
        FROM `dives_eolcnames`
        INNER JOIN `dives` ON `dives`.`id` = `dives_eolcnames`.`dive_id`
        WHERE `dives`.`user_id` = #{self.id} AND `sname_id` IS NOT NULL")
    sp2 = connection.select_values("SELECT DISTINCT(`eolsname_id`) FROM `eolcnames`
        INNER JOIN `dives_eolcnames` ON `eolcnames`.`id` = `dives_eolcnames`.`cname_id`
        INNER JOIN `dives` ON `dives`.`id` = `dives_eolcnames`.`dive_id`
        WHERE `dives`.`user_id` = #{self.id} AND `eolsname_id` IS NOT NULL")
    species += sp2
    species.uniq!
    species_objects = Eolsname.where(:id => species).reject(&:nil?)
    cnames_data = Eolsname.get_cname_data(species)
    return species_objects.map do |s|
      {
        :id => "s-#{s.id}", :sname => s.sname, :rank => s.taxonrank, :category => s.category,
        :url => s.url,
        :picture => s.thumbnail_href,
        :bio => s.eol_description,
        :cnames => cnames_data[s.id]['array_cnames'],
        :preferred_name => cnames_data[s.id]['preferred_cname']
      }
    end
  end

  def update_fb_like
    return if vanity_url.blank?
    FbLike.get self
  end
  handle_asynchronously :update_fb_like


  def public_shops
    s = connection.select_values("SELECT DISTINCT(`shops`.`id`) from `shops` LEFT JOIN `dives` on `shops`.`id` = `dives`.`shop_id` where `dives`.`user_id` = #{self.id} AND `dives`.`privacy` != 1")
    return s.map{|e| Shop.find(e) rescue nil} .reject{|e| e.nil?}
  end

  def global_inbox
    ## generates current user's inbox

    global_inbox = []

    #One section of personal stuff
    personal_stuff = InternalMessage.where(:status => 'new', :to_id => self.id).to_ary

    if personal_stuff.count > 0 then
      global_inbox.push({
        :url => "/settings/messages",
        :name => self.nickname,
        :picture => self.picture,
        :count => {:messages => personal_stuff.count},
        :urls => personal_stuff.map do |message| "/settings/messages/#{message.shaken_id}" end,
        :inbox => personal_stuff
      })
    end

    #One section for each shop admin
    groups = Membership.where(:user_id => self.id, :role => 'admin').includes(:group).map(&:group).to_ary.reject{|e| e.nil?}
    group_ids = groups.map(&:id).uniq.reject(&:nil?)
    shop_ids = groups.map(&:shop_proxy_id).to_ary.uniq.reject(&:nil?)
    shop_ids.push self.shop_proxy_id unless self.shop_proxy_id.nil?
    shop_ids.uniq!

    #initiate sections
    shop_sections = {}
    Shop.where(:id => shop_ids).each do |shop|
      shop_sections[shop.id] ||= {
        :url => shop.fullpermalink(:locale) + "/care",
        :name => shop.name.titleize,
        :picture => shop.user_proxy.picture_small,
        :count => {},
        :urls => [],
        :inbox => []
      }
    end

    group_messages = InternalMessage.includes(:to => :shop_proxy).where(:status => 'new', :to_id => group_ids).to_ary
    group_messages.group_by do |m| m.to.shop_proxy_id end .each do |shop_id, messages|
      shop_sections[shop_id][:count][:messages] = messages.count
      shop_sections[shop_id][:inbox] += messages
      shop_sections[shop_id][:urls] += messages.map do |message| "#{shop_sections[shop_id][:url]}/message/#{message.shaken_id}" end
    end

    Shop.where(:id => shop_ids).each do |s|
      s.pending_signatures.each do |r|
        shop_sections[s.id] = {:count => {}, :inbox => [], :urls => []} if shop_sections[s.id].nil?
        shop_sections[s.id][:count][:signature] = 0 if  shop_sections[s.id][:count][:signature].nil?
        shop_sections[s.id][:count][:signature] += 1
        shop_sections[s.id][:inbox].push r
        shop_sections[s.id][:urls].push "#{s.fullpermalink(:locale)}/edit/care"
      end
    end

    group_baskets = Basket.where(:status => [:paid], :shop_id => shop_ids)
    group_baskets.group_by(&:shop_id).each do |shop_id, baskets|
      shop_sections[shop_id][:count][:baskets] = baskets.count
      shop_sections[shop_id][:inbox] += baskets
      shop_sections[shop_id][:urls] += baskets.map do |basket| "#{shop_sections[shop_id][:url]}/basket/#{basket.shaken_id}" end
    end

    shop_sections.each do |shop_id, section|
      global_inbox.push section unless section[:inbox].empty?
    end

    global_inbox.each do |section|
      section[:url] = section[:urls].first if section[:urls].count == 1
    end

    Rails.logger.debug "INBOX: #{global_inbox}"
    return global_inbox
  end


  def find_external_users
    users = []
    list_em = [self.email, self.contact_email].reject(&:nil?)
    list_fb = [self.fb_id].reject(&:nil?)
    users += ExternalUser.where(:email => list_em).to_ary unless list_em.blank?
    users += ExternalUser.where(:fb_id => list_fb).to_ary unless list_fb.blank?
    users.uniq
  end

  def replace_external_users!
    find_external_users.each do |ex|
      ex.change_into_user! self
    end
  end


  def accept_weekly_notif_email
    begin
      return self.email_subscriptions.where(:scope => "weekly_notif_email").first.subscribed
    rescue
      return nil
    end
  end

  def accept_weekly_notif_email=(val)
    EmailSubscription.change_subscription(self, "weekly_notif_email", val)
  end


  def accept_instant_notif_email
    begin
      return self.email_subscriptions.where(:scope => "instant_notif_email").first.subscribed
    rescue
      return nil
    end
  end

  def accept_instant_notif_email=(val)
    EmailSubscription.change_subscription(self, "instant_notif_email", val)
  end

  def accept_weekly_digest_email
    begin
      return self.email_subscriptions.where(:scope => "weekly_digest_email").first.subscribed
    rescue
      return nil
    end
  end

  def accept_weekly_digest_email=(val)
    EmailSubscription.change_subscription(self, "weekly_digest_email", val)
  end


  def accept_newsletter_email
    begin
      return self.email_subscriptions.where(:scope => "newsletter_email").first.subscribed
    rescue
      return nil
    end
  end

  def accept_newsletter_email=(val)
    EmailSubscription.change_subscription(self, "newsletter_email", val)
  end

  def active?
    ## says if the account is active or not
    !(self.fb_id.nil? && self.email.nil?)
  end



  def ensure_vanity_url
    return true if !self.active?
    return true if !self.vanity_url.nil?
    if self.nickname.nil? || self.nickname == ""
      args = [self.first_name, self.last_name]
    else
      args = [self.nickname]
    end
    Rails.logger.debug "trying to find vanity url with args #{args.to_s}"
    norm_args = []
    args = args.reject{|a| a.nil? || a == ""}
    args.each do |val|
      norm_args.push val.to_url.gsub(/[^a-zA-Z0-9.\-]/n, '').to_s.downcase
    end

    suggested_url= norm_args.join(".").downcase

    while suggested_url.length < 4 do
      suggested_url = (suggested_url + rand.to_s[2])
    end

    if User.find_by_vanity_url(suggested_url).nil? then
      vanity_url = suggested_url
    else
      i=2
      vanity_url = suggested_url.downcase+i.to_s
      while !User.find_by_vanity_url(vanity_url).nil?
        i += 1
        vanity_url = suggested_url+i.to_s
      end
    end
    logger.debug "Generated vanity url #{vanity_url}"
    self.vanity_url = vanity_url
    return vanity_url
  end

  def preferred_locale
    locale = read_attribute(:preferred_locale).to_sym rescue nil
    return :default unless I18n.available_locales.include?(locale)
    return locale
  end

  def preferred_locale=val
    return unless I18n.available_locales.include?(val.to_sym)
    write_attribute(:preferred_locale, val)
  end

  def very_important_diver?
    nb_reviews = Review.where("((CASE mark_orga WHEN NULL THEN 0 ELSE 1 END) + (CASE mark_friend WHEN NULL THEN 0 ELSE 1 END) + (CASE mark_secu WHEN NULL THEN 0 ELSE 1 END) + (CASE mark_boat WHEN NULL THEN 0 ELSE 1 END) + (CASE mark_rent WHEN NULL THEN 0 ELSE 1 END) >= 4 and length(title) > 15 and length(comment) > 150) AND user_id = ?", id).size
    if nb_reviews >= 2
      if dives.size >= 50
        return true
      else
        return false
      end
    else
      return false
    end
  end
  def playOnThisShop id
    if TREASURE_SHOPS.include? id   
      if self.treasures.where("object_id = ?",id).count != 0
        return false
      else
        return true
      end
    else 
      return false
    end
  end
  

private
  def db_buddies=user_list
    id_list = user_list.reject do |b| !(User===b) end .map &:id
    old_buddies = users_buddies.to_ary.reject do |b| !(b.buddy_type == "User") end
    old_id_list = users_buddies.map &:buddy_id
    to_delete = old_buddies.reject do |link| id_list.include?(link.buddy_id) end
    to_delete.each &:destroy
    to_create = id_list - old_id_list
    to_create.each do |buddy_id|
      UsersBuddy.create :user_id => self.id, :buddy_type => 'User', :buddy_id => buddy_id
    end
  end

  def ext_buddies=external_user_list
    id_list = external_user_list.reject do |b| !(ExternalUser===b) end .map &:id
    old_buddies = users_buddies.to_ary.reject do |b| !(b.buddy_type == "ExternalUser") end
    old_id_list = users_buddies.map &:buddy_id
    to_delete = old_buddies.reject do |link| id_list.include?(link.buddy_id) end
    to_delete.each &:destroy
    to_create = id_list - old_id_list
    to_create.each do |buddy_id|
      UsersBuddy.create :user_id => self.id, :buddy_type => 'ExternalUser', :buddy_id => buddy_id
    end
  end
end
