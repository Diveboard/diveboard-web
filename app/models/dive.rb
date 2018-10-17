#include Rails.application.routes.url_helpers # needed to access root_url

### Needs to be deleted using DESTROY method

class Dive < ActiveRecord::Base
  extend FormatApi

  belongs_to :user
  belongs_to :spot
  belongs_to :shop
  belongs_to :trip
  has_many :tanks
  has_many :dive_reviews
  belongs_to :uploaded_profile
  has_many :raw_profile, :class_name => 'ProfileData', :order => 'seconds ASC'
  has_and_belongs_to_many :eolsnames,
                          :join_table => 'dives_eolcnames',
                          :association_foreign_key => 'sname_id',
                          :foreign_key => 'dive_id',
                          :uniq => true

  has_and_belongs_to_many :eolcnames,
                          :join_table => 'dives_eolcnames',
                          :association_foreign_key => 'cname_id',
                          :foreign_key => 'dive_id',
                          :uniq => true

  has_many :signatures

  has_many :dive_gears
  has_many :dive_using_user_gears
  has_many :user_gears, :through => :dive_using_user_gears, :uniq => true
  has_many :picture_album_pictures, :primary_key => 'album_id', :foreign_key => 'picture_album_id', :include => [:picture]
  belongs_to :album, :include => {:picture_album_pictures => :picture}

  has_many :dives_buddies
  has_many :db_buddies, :through => :dives_buddies, :source => :buddy, :source_type => 'User', :uniq => true
  has_many :ext_buddies, :through => :dives_buddies, :source => :buddy, :source_type => 'ExternalUser', :uniq => true

  has_one :fb_comment, :class_name => "FbComments", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id, :order => "fb_comments.updated_at DESC"
  has_many :fb_likes, :class_name => "FbLike", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id

  has_many :activities

  validates_inclusion_of :visibility, :in => %w(bad good average excellent), :allow_nil => true
  validates_inclusion_of :water, :in => %w(salt fresh), :allow_nil => true

  validates :spot_id, :presence => true
  validates :time_in, :presence => true
  validates :duration, :presence => true
  validates :user_id, :presence => true
  validates :maxdepth, :presence => true
  validates :privacy, :presence => true


  cattr_accessor :userid  ## this defines the current user context
  cattr_accessor :prevent_enforce_spot_moderation
  after_save :delete_if_unlinked_to_user
  before_destroy {|record|
                  record.eolcnames.clear
                  record.eolsnames.clear
                  record.buddies.clear
                  connection.execute("DELETE FROM picture_album_pictures WHERE picture_album_id=#{record.album_id}") unless record.album_id.nil?
                  record.signatures.destroy_all
                  record.tanks.destroy_all
                  connection.execute("DELETE FROM profile_data WHERE dive_id=#{record.id}")
                  record.activities.destroy_all ## delete entries from activity feed
                  record.dive_reviews.destroy_all
                  record.save}

  after_save :enforce_spot_moderation
  after_save :lint_if_changed

  before_create :add_number_if_none
  after_create :set_default_gear!
  before_save :compute_score, :check_privacy_flag
  #after_save :check_spot_privacy ### pretty useless imho .....

  define_format_api :public => [
          :id, :shaken_id, :time_in, :duration, :surface_interval, :maxdepth, :maxdepth_value, :maxdepth_unit, :user_id, :spot_id, :temp_surface,
          :temp_surface_value, :temp_surface_unit, :temp_bottom, :temp_bottom_unit, :temp_bottom_value, :privacy, :weights, :weights_value, :weights_unit,
          :safetystops, :safetystops_unit_value, :divetype, :favorite, :visibility, :trip_name, :water, :altitude, :fullpermalink, :permalink,
          :complete, :thumbnail_image_url, :thumbnail_profile_url, :guide, :shop_id, :notes, :public_notes,
          :diveshop, :current, :species, :gears, :user_gears, :dive_gears, :legacy_buddies_hash, :lat, :lng,
          {
            :date => Proc.new {|t| t.time_in.strftime "%Y-%m-%d" },
            :time => Proc.new {|t| t.time_in.strftime "%H:%M" },
            :buddies => Proc.new {|t, options| t.buddies.to_api :public, options},
            :shop => Proc.new {|t| t.shop.to_api :public},
            :dive_reviews => Proc.new {|t| t.dive_reviews_api }
          }],
      :private => [
          :dan_data, :dan_data_sent, :storage_used, :profile_ref,
          {
            :tanks => Proc.new{|t| t.tanks.to_api :public}
          }
          ],
      :dive_profile => [
          {
            :raw_profile => Proc.new {|t| t.raw_profile.to_api(:public)},
          }],
      :mobile => [
          :updated_at, :featured_picture, :pictures, :number,
          {
            :spot => Proc.new {|t| t.spot.to_api :public},
            :featured_gears => Proc.new{|t| t.featured_gears.to_api :public},
            :other_gears => Proc.new{|t| t.other_gears.to_api :public},
            :shop_name => Proc.new{|t| t.shop.name rescue nil},
            :shop_picture => Proc.new{|t| t.shop.user_proxy.picture_large rescue nil if t.shop.user_proxy.pict rescue nil},
            :tanks => Proc.new{|t| t.tanks.to_api :public}
          }
          ],
      :search_light => [
          :shaken_id, :score, :featured_picture_thumbnail, :db_buddy_ids, :featured_picture,
          :id, :time_in, :duration, :maxdepth, :user_id, :spot_id, :temp_surface, :temp_bottom, :privacy, :weights,
          :safetystops, :divetype, :favorite, :buddies, :visibility, :trip_name, :water, :altitude, :fullpermalink ,
          :permalink, :complete, :thumbnail_image_url, :thumbnail_profile_url, :guide, :shop_id, :notes, :public_notes,
          :diveshop, :current,
          {
            :date => Proc.new {|t| t.time_in.strftime "%Y-%m-%d" },
            :time => Proc.new {|t| t.time_in.strftime "%H:%M" },
            #TODO PMA: remove all references to featured_picture_medium
            :featured_picture_medium => proc{|d| d.featured_picture.medium rescue nil}
          }],
      :search_full_server => [:date, :time, :time_in, :diveshop, :duration, :fullpermalink, :id, :maxdepth, :notes, :permalink, :score,
        {  ###db_buddies ???
            user: lambda {|d| d.user.to_api :search_full_server_l1},
            spot: lambda {|d| d.spot.to_api :search_full_server_l1},
            pictures: lambda {|d| d.pictures[0..20].map do |p| p.to_api :public end },
          }],
      :search_full_server_l1 => [:date, :duration, :time_in, :featured_picture_thumbnail, :id, :maxdepth, :notes, :permalink, :score,
        {
            user: lambda {|d| d.user.to_api :search_full_server_l2},
            spot: lambda {|d| d.spot.to_api :search_full_server_l2}
          }],
      :search_full_server_l2 => [ :date, :time, :time_in, :duration, :maxdepth,
            user: lambda {|d| d.user.to_api :search_full_server_l2},
            spot: lambda {|d| d.spot.to_api :search_full_server_l2}
          ],
      :search_full => [ :picture_ids ]

  define_api_includes :private => [:public], :mobile => [:private], :search_full => [:search_light, :public]
  define_api_private_attributes :dan_data, :dan_data_sent, :storage_used, :profile_ref
  define_api_conditional_private_attributes lambda {|dive|
    [:notes] unless dive.user && dive.user.share_details_notes
  }
  define_api_updatable_attributes %w( user_id time_in duration surface_interval maxdepth maxdepth_unit maxdepth_value notes temp_surface temp_surface_unit temp_surface_value temp_bottom temp_bottom_unit temp_bottom_value safetystops safetystops_unit_value divetype favorite buddies visibility trip_name water altitude altitude_unit altitude_value weights weights_unit weights_value dan_data current number profile_ref species send_to_dan diveshop guide request_shop_signature privacy dive_reviews) ###TODO: remove user_id from there
  define_api_updatable_attributes_rec 'spot' => Spot, 'tanks' => Tank, 'user_gears' => UserGear, 'dive_gears' => DiveGear, 'pictures' => Picture, 'shop' => Shop, 'raw_profile' => ProfileData
  define_api_requiring_id %w(tanks user_gears dive_gears pictures raw_profile buddies species dive_reviews)
  #gears

  default_scope order("dives.time_in desc")


  def is_reachable_for?(options = {})
    begin
      return true if options[:private]
      return true if self.is_private_for?(options)
      return false if self.privacy == 1
      return true
    rescue
      return true
    end
  end

  def is_private_for?(options = {})
    begin
      return true if self.user_id.nil? #well.... not really....
      return true if options[:private]
      return true if options[:caller].id == self.user_id rescue false
      return true if self.user.is_private_for?(options) rescue false
      return false
    rescue
      return false
    end
  end

  def check_privacy_flag
    if self.privacy.nil? then
      if self.user && self.user.auto_public then
        self.privacy = 0
      else
        self.privacy = 1
      end
    end

    begin
      if self.privacy == 0
        raise DBArgumentError.new "Spot id is nil" if self.spot_id.nil?
        #s = Spot.find(self.spot_id)
        #raise DBArgumentError.new "Spot #{self.spot_id}'s country id is 1" if s.country_id == 1
        #raise DBArgumentError.new "Spot #{self.spot_id}'s location id is 1" if s.location_id == 1
      end
    rescue
      logger.warn "Changing privacy back to 1 since: #{$!.message}"
      self.privacy = 1
    end
  end

  def spot=(val)
    if val.is_a? Spot
      self.spot_id = val.id
    else
      self.spot_id = nil
    end
  end

  def spot_id=(val)
    if !val.nil?
      s = Spot.find(val)
      ##check spot status
      if val == 1
        write_attribute(:spot_id, 1) # we need to ensure that default spot does not get moderated
        spot.reload
      elsif s.private_user_id != self.user_id && !s.is_visible_for?(self.user_id) then
        ##we need to duplicate the spot for user_id to have it too
        Rails.logger.debug "We need to duplicate spot with id #{val.to_s}"
        s = s.duplicate
        s.private_user_id = self.user_id
        s.save!
        Rails.logger.debug "New spot with id #{s.id} created"
      end
      write_attribute(:spot_id, s.id)
      spot.reload
    else
      write_attribute(:spot_id, 1)
      spot.reload
    end
  end

  def visibility=(val)
    if val.nil? then
      write_attribute(:visibility, val)
      return
    end

    # Get the allowed values from the DB schema
    values = ['bad','average','good','excellent']

    raise DBArgumentError.new "Invalid visibility type.", allowed: values unless values.include?(val)
    write_attribute(:visibility, val)
  end

  def check_spot_privacy
    ##ensure we are allowed to use that spot
    if self.spot.is_visible_for? self.user_id
      return
    elsif self.spot.private_user_id == self.user_id
      return
    else
      raise DBArgumentError.new "Spot is not public and doesn't belong to user"
    end
  end


  def water=(val)
    if val.nil? then
      write_attribute(:water, val)
      return
    end

    # Get the allowed values from the DB schema
    values = ['salt', 'fresh']

    raise DBArgumentError.new "Invalid water type", allowed: values unless values.include?(val)
    write_attribute(:water, val)
  end

  def current=(val)
    if val.nil? then
      write_attribute(:current, val)
      return
    end

    # Get the allowed values from the DB schema
    values = ['none','light','medium','strong','extreme']

    raise DBArgumentError.new "Invalid current value", allowed: values unless values.include?(val)
    write_attribute(:current, val)
  end

  def weights=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        begin
          val = JSON.parse(val)
        rescue
          raise DBArgumentError.new("Could not understand value", value: val)
        end
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      raise DBArgumentError.new 'Weights must be positive or zero' if val < 0
      if self.user.nil? || (!self.user.nil? && self.user.unitSI?)
        write_attribute(:weights_unit, "kg")
        write_attribute(:weights_value, val)
      else
        write_attribute(:weights_unit, "lbs")
        write_attribute(:weights_value, DBUnit.convert(val, "kg", "lbs"))
      end
    elsif val.class.to_s == "Hash"
      raise DBArgumentError.new 'Weights must be positive or zero' if val["value"] < 0
      write_attribute(:weights_unit, val["unit"])
      write_attribute(:weights_value, val["value"],to_f)
    elsif val.nil?
      write_attribute(:weights_unit, nil)
      write_attribute(:weights_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def weights unit=0
    if id != 1
      if unit == 0
        #SI (default)
        return DBUnit.convert(weights_value, weights_unit || "kg", "kg")
      else
        #IMPERIAL
        return DBUnit.convert(weights_value, weights_unit || "kg", "lbs")
      end
    else
      return nil
    end
  end

  def weights_unit=(val)
    if val.match(/^kg$/i)
      write_attribute(:weights_unit, "kg")
    elsif val.match(/^lbs$/i)
      write_attribute(:weights_unit, "lbs")
    else
      raise DBArgumentError.new "#{val} is not an acceptable weights_unit"
    end
  end




  def favorite=(val)
    raise DBArgumentError.new "Invalid favorite flag" unless [nil, true, false, 'true', 'false'].include?(val)
    write_attribute(:favorite, val)
  end

  def notes
    n = read_attribute(:notes)
    return n unless n.blank?
  end

  def public_notes
    notes if user && user.share_details_notes
  end


  def lat
    spot.lat
  end

  def lng
    spot.lng
  end
  def lastmod
    lastmod = self.updated_at
    self.pictures.each do |picture|
      if picture.updated_at > lastmod
        lastmod = picture.updated_at
      end
    end
    if self.spot.updated_at > lastmod
      lastmod = self.spot.updated_at
    end
    return lastmod.to_date
  end

  def label
    [spot.name, spot.location.name, spot.country.name].reject(&:blank?).join ", "
  end



  def static_map_url
      self.spot.static_map_url
  end


  def divetype=(divetypes)
    if divetypes.nil? || divetypes == [] then
      write_attribute(:divetype, nil )
      return
    end
    divetypes = [divetypes] if divetypes.is_a? String
    divetype_clean =[]
    divetypes.each do |divetype|
      divetype_split = divetype.gsub(/\ *,\ */, ",").split(",")
      if divetype_split != []
        divetype_split.each do |divetypedata|
          divetype_clean << divetypedata
        end
      end
    end
    write_attribute(:divetype, divetype_clean.to_json )
  end

  def divetype
    if id == 1 then
      return []
    end
    types = read_attribute(:divetype)
    begin
      if types.nil? || types.empty? then
        return []
      else
        type_list = JSON.parse(types)
        return type_list
      end
    rescue
      return []
    end
  end

  def time_in
    if id != 1
      return read_attribute(:time_in)
    else
      return Time.now
    end
  end


  def time_in=(val)
    ##ensure the date is properly formatted otherwise Time.now
    begin
      write_attribute(:time_in, Time.parse("#{val} UTC".gsub(".",":")))
    rescue
      Rails.logger.debug "Dive time is ill formatted got #{val} which could not be parsed : #{$!.message}"
      raise DBArgumentError.new "Dive time is ill formatted"
    end
  end

  def duration
    if id != 1
      return read_attribute(:duration)
    else
      return nil
    end
  end

  def maxdepth=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        begin
          val = JSON.parse(val)
        rescue
          raise DBArgumentError.new("Could not understand value", value: val)
        end
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      if self.user.nil? || (!self.user.nil? && self.user.unitSI?)
        write_attribute(:maxdepth_unit, "m")
        write_attribute(:maxdepth_value, val)
      else
        write_attribute(:maxdepth_unit, "ft")
        write_attribute(:maxdepth_value, DBUnit.convert(val, "m", "ft"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:maxdepth_unit, val["unit"])
      write_attribute(:maxdepth_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:maxdepth_unit, nil)
      write_attribute(:maxdepth_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def maxdepth unit=0
    if id != 1
      return 0 if maxdepth_value.nil?
      if unit == 0
        #SI (default)
        return DBUnit.convert(maxdepth_value, maxdepth_unit || "m", "m")
      else
        #IMPERIAL
        return DBUnit.convert(maxdepth_value, maxdepth_unit || "m", "ft")
      end
    else
      return nil
    end
  end


  def maxdepth_unit=(val)
    if val.match(/^m$/i)
      write_attribute(:maxdepth_unit, "m")
    elsif val.match(/^ft$/i)
      write_attribute(:maxdepth_unit, "ft")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable maxdepth_unit", :val => val
    end
  end


  def altitude=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        begin
          val = JSON.parse(val)
        rescue
          raise DBArgumentError.new("Could not understand value", value: val)
        end
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      write_attribute(:altitude_unit, "m")
      write_attribute(:altitude_value, val)
    elsif val.class.to_s == "Hash"
      write_attribute(:altitude_unit, val["unit"])
      write_attribute(:altitude_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:altitude_unit, nil)
      write_attribute(:altitude_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end


  def altitude unit=0
    if id != 1
      if unit == 0
        #SI (default)
        return DBUnit.convert(altitude_value, altitude_unit || "m", "m")
      else
        #IMPERIAL
        return DBUnit.convert(altitude_value, altitude_unit || "m", "ft")
      end
    else
      return nil
    end
  end

  def altitude_unit=(val)
    if val.match(/^m$/i)
      write_attribute(:altitude_unit, "m")
    elsif val.match(/^ft$/i)
      write_attribute(:altitude_unit, "ft")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable altitude_unit", :val => val
    end
  end

  def temp_bottom=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        begin
          val = JSON.parse(val)
        rescue
          raise DBArgumentError.new("Could not understand value", value: val)
        end
      end
    end
    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      if self.user.nil? || (!self.user.nil? && self.user.unitSI?)
        write_attribute(:temp_bottom_unit, "C")
        write_attribute(:temp_bottom_value, val)
      else
        write_attribute(:temp_bottom_unit, "F")
        write_attribute(:temp_bottom_value, DBUnit.convert(val, "C", "F"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:temp_bottom_unit, val["unit"])
      write_attribute(:temp_bottom_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:temp_bottom_unit, nil)
      write_attribute(:temp_bottom_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end


  def temp_bottom unit=0
    if id != 1
      if unit == 0
        #SI (default)
        return DBUnit.convert(temp_bottom_value, self.temp_bottom_unit || "C", "C")
      else
        #IMPERIAL
        return DBUnit.convert(temp_bottom_value, self.temp_bottom_unit || "C", "F")
      end
    else
      return nil
    end
  end

  def temp_bottom_unit=(val)
    if val.match(/^C$/i)
      write_attribute(:temp_bottom_unit, "C")
    elsif val.match(/^F$/i)
      write_attribute(:temp_bottom_unit, "F")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable temp_bottom_unit", :val => val
    end
  end


  def temp_surface=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        begin
          val = JSON.parse(val)
        rescue
          raise DBArgumentError.new("Could not understand value", value: val)
        end
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      if self.user.nil? || (!self.user.nil? && self.user.unitSI?)
        write_attribute(:temp_surface_unit, "C")
        write_attribute(:temp_surface_value, val)
      else
        write_attribute(:temp_surface_unit, "F")
        write_attribute(:temp_surface_value, DBUnit.convert(val, "C", "F"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:temp_surface_unit, val["unit"])
      write_attribute(:temp_surface_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:temp_surface_unit, nil)
      write_attribute(:temp_surface_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def temp_surface unit=0
    if id != 1
      if unit == 0
        #SI (default)
        return DBUnit.convert(temp_surface_value, self.temp_surface_unit || "C", "C")
      else
        #IMPERIAL
        return DBUnit.convert(temp_surface_value, self.temp_surface_unit || "C", "F")
      end
    else
      return nil
    end
  end


  def temp_surface_unit=(val)
    if val.match(/^C$/i)
      write_attribute(:temp_surface_unit, "C")
    elsif val.match(/^F$/i)
      write_attribute(:temp_surface_unit, "F")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable temp_surface_unit", val: val
    end
  end

  def safetystops=(val)
    ## check that each stop has at least 2 value [depth , duration, unit]
    if val.nil?
      write_attribute(:safetystops, nil)
    else
      stops = JSON.parse(val)
      stops.reject!{|e|
        (e[1] == "" || e[1].nil?) && (e[2] == "" || e[2].nil?)
      }
      stops.map{|s|
        if !s[2].nil? && !(s[2].match(/^ft$/) || s[2].match(/^m$/))
          raise DBArgumentError.new "Unit is not an acceptable depth unit on safetystops", :unit => s[2], :val => val
        elsif s[2].nil?
          s[2] = "m"
        end
        s
      }
      write_attribute(:safetystops, stops.to_json)
    end

  end



  def safetystops unit=0
    begin
      stop  = JSON.parse(read_attribute(:safetystops))
    rescue
      return nil
    end
    if id != 1
      return (stop.map{|s|
        depth_unit = "m"
        depth_unit = "ft" if s[2] && s[2].match(/^ft$/i)
        if unit == 0
        #SI (default)
           [DBUnit.convert(s[0], depth_unit, "m"), s[1]]
        else
          #IMPERIAL
           [DBUnit.convert(s[0], depth_unit, "ft"), s[1]]
        end
      }).to_json
    else
      return nil
    end
  end

  def safetystops_unit_value
    begin
      s = read_attribute(:safetystops)
      return nil if s.nil?
      ss = JSON.parse(s)
      ss.map{|stop|
        if stop[2].nil?
          stop[2] = "m"
        end
        stop
      }
      return ss.to_json
    rescue
      return nil
    end
  end


  def safetystops_unit_value=(val)
    self.safetystops = val
  end

  def date
    #gives date in format mm/dd/yy (or sth like that)
    "#{time_in.to_date}"
  end

  def time
    # how long did the dive go
    "#{time_in.to_formatted_s(:time)}"
  end

  def time_hrs
    # how long did the dive go
    "#{time_in.hour}"
  end
  def time_mins
    # how long did the dive go
    "#{time_in.min}"
  end

  def recent_unique_divers(nb)
    #gives back an arrray of divers who went in the same :location order by date desc and with no duplicated divers
    Dive.select('dives.*').joins(:spot,:user).where("spots.location_id = ? and users.fb_id != ? and dives.privacy = 0", "#{self.spot.location_id}",  user_id).group("user_id").limit(nb).to_ary
  end

  def recent_unique_pictures(nb)
    ## pictures in a given spot but not from the dive's owner
    #Dive.from("picture_album_pictures, dives, spots").where("picture_album_pictures.picture_album_id=dives.id and dives.spot_id=spots.id").where("spots.location_id = ? and dives.user_id != ? and dives.privacy = 0", "#{self.spot.location_id}",  user_id).group("user_id").limit(4).to_ary
    Picture.select('pictures.*')
      .joins("JOIN spots USE INDEX (index_spots_on_location_id), dives, picture_album_pictures")
      .where("pictures.id = picture_album_pictures.picture_id")
      .where("picture_album_pictures.picture_album_id=dives.album_id")
      .where("dives.spot_id = spots.id")
      .where("dives.privacy <> 1 AND spots.location_id = ? AND dives.user_id != ?", self.spot.location_id,  self.user_id)
      .order("pictures.created_at").group('dives.id').limit(nb)
  end

  def recent_dives(nb)
    Dive.where("user_id IS NOT NULL").where("privacy <> 1").group("user_id").limit(nb)
  end

  def recent_pictures(nb)
    #Dive.from("picture_album_pictures, dives").where("dives.id = picture_album_pictures.picture_album_id and dives.privacy=0").group('dives.id').limit(nb)
    Picture.select('pictures.*').joins("LEFT JOIN picture_album_pictures on pictures.id = picture_album_pictures.picture_id LEFT JOIN dives on picture_album_pictures.picture_album_id=dives.album_id").where("dives.privacy <> 1").order("pictures.created_at").group('dives.id').limit(nb)
  end

  def complete
    # says if dive is complete
    if !self.maxdepth.nil? && self.spot_id != 1 && !self.duration.nil?
      return true
    else
      return false
    end
  end

  def complete?
    self.complete
  end
  def draft?
    !self.complete
  end

  def picture_count
    return 0 if album_id.nil?
    PictureAlbumPicture.where(:picture_album_id => album_id).count
  end

  def pictures
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture).to_ary
  end

  def picture_ids
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture_id).to_ary
  end

  def pictures_with_eol
    Picture.unscoped.select('pictures.*').includes([:user, :cloud_small, :cloud_medium, :cloud_original_image, :cloud_large, :cloud_thumb, :eolcnames, :eolsnames, {:eolcnames => :eolsname}]).joins(" JOIN  picture_album_pictures").where("picture_album_pictures.picture_album_id = :id and picture_album_pictures.picture_id = pictures.id", {:id => self.album_id}).order("picture_album_pictures.ordnum")
  end

  def pictures_with_cloud
    Picture.unscoped.select('pictures.*').includes([:user, :cloud_small, :cloud_medium, :cloud_original_image, :cloud_large, :cloud_thumb]).joins(" JOIN  picture_album_pictures").where("picture_album_pictures.picture_album_id = :id and picture_album_pictures.picture_id = pictures.id", {:id => self.album_id}).order("picture_album_pictures.ordnum")
  end

  def pictures=(added_pictures)
    begin
      @require_lint ||= added_pictures.first != self.pictures.first
    rescue
    end
    if self.album_id.nil? then
      album = Album.create :user_id => self.user_id, :kind => 'dive'
      self.album_id = album.id
    end
    Picture.transaction {
      self.class.connection.execute("DELETE FROM picture_album_pictures WHERE picture_album_id = #{self.album_id}")
      args = []
      added_pictures.each do |pic|
        pic.save if pic.new_record?
        args.push "(#{self.album_id}, #{pic.id})"
      end
      self.class.connection.execute("INSERT INTO picture_album_pictures (picture_album_id, picture_id) VALUES #{ args.join(',') }") unless args.count == 0
    }
    return added_pictures
  end

  def featured_picture
    return self.pictures.first
  end

  def other_firsts_pictures
    return self.pictures[1..7]
  end

  def thumbnail_image_url
    ## returns a url to an image representing the dive (picture or map)
    begin
      if self.pictures.empty?
        return self.static_map_url.html_safe
      else
        return self.pictures.first.thumbnail
      end
    rescue
      return self.static_map_url.html_safe
    end
  end

  def generate_image_tag
    ##generates the image/video OG_TAG for the dive
    if self.pictures.empty?
       return "<meta property=\"og:image\" content=\"#{self.static_map_url.html_safe}\">"
    else
        return self.pictures.first.og_tag
    end
  end

  def has_profile_data?
    return false if self.id.nil? || self.id == 0
    log = Divelog.new
    log.fromDiveDB(self.id)
    has_profile = false
    log.dives.each { |dive|
      has_profile = true if !dive["sample"].nil? && !dive["sample"][0].nil?
    }
    return has_profile
  end

  def profile_data_udcf
    log = Divelog.new
    log.fromDiveDB(self.id)
    has_profile = false
    log.dives.each { |dive|
      has_profile = true if !dive["sample"].nil? && !dive["sample"][0].nil?
    }
    if !has_profile then
      return nil
    else
      return log.toUDCF
    end
  end

  def thumbnail_profile_url
    if self.raw_profile.count == 0 || self.duration.nil? || self.duration == 0 then
      return nil
    else
      return (HtmlHelper.lbroot "/#{user.vanity_url}/#{id}/profile.png?g=small_or&u=m&locale=#{I18n.locale}")
    end
  end

  def profile_svg_url version, unit
    return (HtmlHelper.lbroot "/#{user.vanity_url}/#{id}/profile.svg?g=#{version}&u=#{unit}&locale=#{I18n.locale}")
  end

  def post_to_wall
    #Post the current dive to the user's wall

    #logger.debug "Creating a wall post"
    #myuser = User.find(user_id)
    begin
      @graph = Koala::Facebook::API.new(self.user.fbtoken)
      @graph.get_object("me")
      #TODO find a nicer way to handle ROOT_URL than define it in development.rb ...
      #TODO change the link to a post with more details http://developers.facebook.com/docs/reference/api/post/

      logger.debug "posting with those args : "+ { :name => "#{user.nickname}'s dive in #{self.spot.name.titleize} - #{self.spot.location.name.titleize}",
        :link => "#{ROOT_URL}#{self.user.vanity_url}/#{self.id.to_s}",
        :icon =>"#{ROOT_URL}fb_ico.gif",
        :actions => {:name => "View Dive", :link => "#{ROOT_URL}#{self.user.vanity_url}?dive=#{self.id.to_s}"},
        :description => "Depth: #{self.maxdepth}m Duration: #{self.duration}mins - #{self.notes}",
        :picture => "#{self.thumbnail_image_url}"
        }.to_s

      @graph_object = @graph.put_wall_post("#{user.nickname} has just shared a new scuba dive on Diveboard",
                            { :name => "#{user.nickname}'s scuba dive in #{self.spot.name.titleize} - #{self.spot.location.name.titleize}",
                              :link => "#{ROOT_URL}#{self.user.vanity_url}/#{self.id.to_s}",
                              :icon =>"#{ROOT_URL}fb_ico.gif",
                              :actions => {:name => "View Dive", :link => "#{ROOT_URL}#{self.user.vanity_url}?dive=#{self.id.to_s}"},
                              :description => "Depth: #{self.maxdepth}m Duration: #{self.duration}mins - #{self.notes}",
                              :picture => "#{self.thumbnail_image_url}"
                              })
      if @graph_object != false
        ## if user has opted out it may return false
        self.graph_id = @graph_object["id"]
        self.save
      end
      #graph_id = "12345_12345"
    rescue Koala::Facebook::APIError => exc
      #TODO Catch Koala::Facebook::APIError: OAuthException: (#506) Duplicate status message
      #TODO Koala::Facebook::APIError: OAuthException: (#341) Feed action request limit reached
      #TODO Koala::Facebook::APIError: OAuthException: Error validating access token.
      #TODO Catch the opengraph id and add it to the Database.
      logger.warn "Fail in koala, APIERROR #{exc.message}"
      #self.graph_id = exc.message
      self.save
    rescue Errno::ETIMEDOUT => exc
      logger.warn "Fail in koala, TIMEOUT #{exc.message}"
      self.save
    end
  end

  def species_sci_ids
    return (self.eolsnames.map(&:id) + self.eolcnames.map(&:eolsname).map(&:id)).uniq
  end

  def species
    ##will return an array of species { :name => "", :link => "", :sci_name => ""}
    ## asselbles the eolcnames and eolsnames from a given dive
    ## for eolsnames name == sci_name

    eols = self.eolsnames.to_ary
    eolc = self.eolcnames.to_ary
    result = []
    eolc.each do |species|
      eols.push species.eolsname
    end
    eols.each do |s|
      result << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank, :category => s.category, :category_inspire => s.category_inspire}
    end
    ##for some reasons there may have been duplicates here
    return result.uniq
  end

  def species=(fish_list)
    fish_list = [] if fish_list.nil?
    dive_cnames = []
    dive_snames = []
    fish_list.each do |fish|
      fishid = fish[:id] || fish['id'] rescue nil
      raise DBArgumentError.new "Species id not valid", in: fish.to_s if fishid.nil?
      logger.debug "Adding species id: #{fishid}"
      begin
        if  !(fishnum = fishid.match(/^c-([0-9]*)$/)).nil?
          dive_cnames << Eolcname.find(fishnum[1])
        elsif  !(fishnum = fishid.match(/^s-([0-9]*)$/)).nil?
          dive_snames << Eolsname.find(fishnum[1])
        else
          raise DBArgumentError.new "id not valid for fish", id: fishid
        end
      rescue ActiveRecord::RecordNotFound => e
        raise DBArgumentError.new "id for fish does not exist", id: fishid
      end
    end
    self.eolcnames = dive_cnames
    self.eolsnames = dive_snames
  end

  #returns the Eolcnames of the dive, including the eolcnames tagged in pictures
  def all_eolcnames
    [].concat(self.eolcnames).concat(self.pictures_with_eol.map(&:eolcnames).flatten).uniq
  end
  def all_eolsnames
    [].concat(self.eolsnames).concat(self.pictures_with_eol.map(&:eolsnames).flatten).uniq
  end

  def user_id= val
    write_attribute(:user_id, User.idfromshake(val))
  end

  def diveshop
    s = {}

    #overloading with data coming from the link if available
    if !self.shop.nil? then
      s['id'] = self.shop.id
      s['name'] = self.shop.name
      s['url'] = self.shop.fullpermalink(:locale) unless self.shop.fullpermalink(:locale).blank? #
    end

    s['guide'] = self.guide unless self.guide.nil?

    if s['name'].blank? && s['guide'].blank? then
      return nil
    else
      return s
    end
  end

  def diveshop=(val)
    Rails.logger.debug "doing the diveshop dance"
    if val.blank?
      self.shop_id = nil
    else
      raise DBArgumentError.new "diveshop should be a hash" unless val.is_a? Hash
      self.shop_id = val["id"].to_i unless val["id"].blank?
      self.guide = val["guide"].to_i unless val["guide"].blank?

      if val["id"].blank?
        #we need to create a new shop and put it to moderation
        s = Shop.new
        s.web = val["url"]
        s.name = val["name"]
        s.address = "#{val["country"] || ""} #{val["town"] || ""}"
        s.flag_moderate_private_to_public = true
        s.private_user_id = self.user_id
        s.save!
        self.shop_id = s.id
      end
    end
    self.save
  end

  def legacy_buddies_hash
    all = []
    ext_buddies.each do |buddy|
      all.push({
        'name' => buddy.nickname,
        'email' => buddy.email,
        'picturl' => buddy.picturl,
        'fb_id' => buddy.fb_id
      })
    end
    db_buddies.each do |buddy|
      all.push({
        'name' => buddy.nickname,
        'picturl' => buddy.picture,
        'db_id' => buddy.id
      })
    end
    return all
  end


  def buddies
    all = []
    all += self.ext_buddies
    all += self.db_buddies
  end

  #takes some JSON as input
  def buddies=args
    Dive.transaction do
      args = JSON.parse(args) if String === args
      args = [] if args.nil?

      new_db_buddies = []
      new_ext_buddies = []
      failed_buddies = []
      args.each do |bud|
        begin
          if !bud['db_id'].blank? then
            new_user = User.find bud['db_id']
            new_db_buddies.push(new_user)
          elsif bud['class'] == 'User' && !bud['id'].blank? then
            new_user = User.find bud['id']
            new_db_buddies.push(new_user)
          else
            new_user = ExternalUser.find_or_create(self.user, bud)
            next if new_user.nil?
            #attempted external user may potentially exist in diveboard, and thus belongs to db_buddies
            if ExternalUser === new_user then
              new_ext_buddies.push(new_user)
            else
              new_db_buddies.push(new_user)
            end
          end
          if bud['notify'] == true
            Rails.logger.debug "NOTIFY NEW BUDDY form #{new_user.class.to_s} !!! #{new_user.id}"
            ## FIX SYCK ISSUE NotifyUser.delay.notify_buddy_added(new_user, self)
            if new_user.is_a? User then
              Notification.create :kind => 'tag_dive', :user_id => new_user.id, :about => self
            else
              begin
                NotifyUser.notify_buddy_added(new_user, self).deliver
              rescue
                 Rails.logger.debug "NOTIFY NEW BUDDY failed  : #{$!.message}"
              end
            end
          end

        rescue
          bud['error'] = $!.message
          failed_buddies.push bud
        end
      end

      self.db_buddies = new_db_buddies
      self.ext_buddies = new_ext_buddies
      self.buddies
      if !failed_buddies.empty?
        raise DBArgumentError.new "could not add buddies", failed_buddies: failed_buddies
      end
    end
  end

  # takes strictly a list of Users
  def db_buddies=user_list
    DivesBuddy.transaction do
      id_list = user_list.reject do |b| !(User===b) end .map &:id
      old_buddies = dives_buddies.to_ary.reject do |b| !(b.buddy_type == "User") end
      old_id_list = dives_buddies.map &:buddy_id
      to_delete = old_buddies.reject do |link| id_list.include?(link.buddy_id) end
      to_delete.each &:destroy
      to_create = id_list - old_id_list
      to_create.each do |buddy_id|
        DivesBuddy.create :dive_id => self.id, :buddy_type => 'User', :buddy_id => buddy_id
      end
    end
  end

  # takes strictly a list of ExternalUsers
  def ext_buddies=external_user_list
    DivesBuddy.transaction do
      id_list = external_user_list.reject do |b| !(ExternalUser===b) end .map &:id
      old_buddies = dives_buddies.to_ary.reject do |b| !(b.buddy_type == "ExternalUser") end
      old_id_list = dives_buddies.map &:buddy_id
      to_delete = old_buddies.reject do |link| id_list.include?(link.buddy_id) end
      to_delete.each &:destroy
      to_create = id_list - old_id_list
      to_create.each do |buddy_id|
        DivesBuddy.create :dive_id => self.id, :buddy_type => 'ExternalUser', :buddy_id => buddy_id
      end
    end
  end


  def avg_depth(start, stop)

    start = 0 if start.nil?
    stop = ProfileData.where(:dive_id => self.id).maximum(:seconds) if stop.nil?

    if stop.nil? || stop <= 0 then
      return nil
    end

    prev_pos = nil
    avg_sum = 0

    profile = Media.select_all_sanitized "select seconds, depth from profile_data where dive_id = :dive_id order by seconds", :dive_id => self.id
    profile.each do |pos|
      prev_pos = pos if prev_pos.nil?

      if pos['depth'].nil? then
        next
      end

      #if start is not exacly a measure, we interpole the estimated depth
      if pos['seconds'] > start && prev_pos['seconds'] < start then
        prev_pos['depth'] = prev_pos['depth'] + (start - prev_pos['seconds']) * (pos['depth'] - prev_pos['depth']) / (pos['seconds'] - prev_pos['seconds'])
        prev_pos['seconds'] = start
      end

      #if stop is not exacly a measure, we interpole the estimated depth
      if pos['seconds'] > stop && prev_pos['seconds'] < stop then
        pos['depth'] = prev_pos['depth'] + (stop - prev_pos['seconds']) * (pos['depth'] - prev_pos['depth']) / (pos['seconds'] - prev_pos['seconds'])
        pos['seconds'] = stop
      end

      if pos['seconds'] > start && pos['seconds'] <= stop then
        #logger.debug "#{pos.seconds} : depth of #{(pos.depth + prev_pos.depth)/2} for #{pos.seconds - prev_pos.seconds} seconds | currently on #{avg_sum}"
        avg_sum += (pos['seconds'] - prev_pos['seconds']) * (pos['depth'] + prev_pos['depth']) / 2
      end

      prev_pos = pos

    end

    return (avg_sum / (stop - start))

  end

  def gears
    all_gears = self.dive_gears.to_ary.dup
    self.dive_using_user_gears.includes(:user_gear).each do |link|
      link.user_gear.featured = link.featured
      all_gears.push link.user_gear
    end
    all_gears.uniq
  end

  def featured_gears
    gears.reject{|g| !g.featured}
  end

  def other_gears
    gears.reject{|g| g.featured}
  end

  def user_gears
    self.dive_using_user_gears.includes(:user_gear).map do |link|
      next if link.user_gear.nil?
      link.user_gear.featured = link.featured
      link.user_gear
    end
  end

  def user_gears=(list)
    begin
    if list.nil? or list == [] then
      self.dive_using_user_gears = []
      return
    end
    old_duug_list = DiveUsingUserGear.where(:dive_id => self.id).to_ary
    duug_list = []
    list.each do |gear|
      gear.user_id = self.user_id if gear.user_id.nil?
      raise DBArgumentError.new "UserGear do not belong to dive owner", :gear_id => gear.id, :dive_id => self.id, :dive_user_id => self.user_id if gear.user_id != self.user_id
      gear.save! if gear.new_record?
      link = DiveUsingUserGear.new
      link.dive_id = self.id
      link.user_gear_id = gear.id
      link.featured = gear.featured || false
      link.save!
      duug_list.push link
    end
    old_duug_list.map &:destroy
    #TODO: catch/raise to be done ?
    rescue
      Rails.logger.debug $!.backtrace.join("\n")
      raise $!
    end
  end

  def set_default_gear!
    if self.user_gears.length == 0 then
      l = user.user_gears.where(:auto_feature => ['featured', 'other']).to_ary
      l.each do |a| a.featured = (a.auto_feature == 'featured') end
      self.user_gears = l
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

  def dan_data_sent
    return JSON.parse(read_attribute(:dan_data_sent)) unless read_attribute(:dan_data_sent).nil?
  end

  def dan_data_sent=(v)
    if v.nil? then
      write_attribute(:dan_data_sent, nil)
    else
      write_attribute(:dan_data_sent, v.to_json)
    end
  end

  def storage_used
    begin
      pictures.map(&:size).sum
    rescue
      0
    end
  end


  def compute_score
    #caching score to prevent recalculating
    return @computed_score if @computed_score
    begin
      self.score = 0
      pics = self.pictures
      pics.each do |p|
        self.score += 3 if p.great_pic
      end
      self.score += 10 if pics.first && pics.first.great_pic
      self.score += 5 if pics.count > 0
      self.score += 4 if self.public_notes && self.public_notes.length > 50
      self.score += 2 if self.favorite
      self.score += 3 if self.diveshop
      self.score += 1 if self.ext_buddies.count > 0 || self.db_buddies.count > 0
      self.score -= 5 if self.spot_id.nil? || self.spot.name == ""
      self.score -= 2 if self.maxdepth.nil? || self.maxdepth <= 1
    rescue
      Rails.logger.debug "Could not compute score for dive #{self.id} : #{$!.message}"
    end
    @computed_score = self.score
    return self.score
  end

  def compute_score!
    @computed_score = nil
    compute_score
  end

  def add_number_if_none
    if self.number.nil?
      auto_number
    end
  end

  def auto_number
    begin
      self.number = self.user.total_ext_dives + self.user.dives.count
      if self.number == 0
        self.number = 1
      elsif self.user.dives.count > 1 && !self.user.dives.first.nil?  && !self.user.dives.first.number.nil?
        self.number = self.user.dives.first.number+1
      end

      return self.number
    rescue
      logger.debug "could not auto_number"
      return self.number
    end
  end

  def lint_if_changed
    return if changed_attributes.include? 'id'
    if changed_attributes.slice('spot_id', 'maxdepth', 'notes' ).count > 0 || @require_lint then
      fb_lint_me
    end
  end

  def fb_lint_me
    ## this will update Facebook's view of the page o it displays nicely
    require 'open-uri'
    if self.privacy == 1
      ##don't lint a private page - it's useless
      return false
    end
    begin

      ##ensure we don't have a lint in progress
      Delayed::Job.where("handler like '%fb_lint_me_without_delay%' and handler like '%#{self.id}%'").all.each do |j|
        begin
          if j.name == "Dive#fb_lint_me_without_delay" && j.payload_object.id == self.id
            return false
          end
        rescue
        end
      end

      fb_lint_url = "https://developers.facebook.com/tools/debug/og/object?format=json&q="
      fbcall = open("#{fb_lint_url}#{CGI::escape(self.fullpermalink(:canonical))}").read
      response = JSON.parse( fbcall)
      if !response["critical"].nil?
        ## TODO : notify the pope
        self.graph_lint = 0
        self.save
        return false
      end
      response["info"].each do |f|
        if f["type"]=="og:updated_time"
          self.graph_lint = Time.at (f["message"].to_i)
          self.save
          if Time.now - self.graph_lint < 50
            return true
          else
            return false
          end
        end
      end
        return false
    rescue
      Rails.logger.debug $!.message
      Rails.logger.debug $!.backtrace
      return false
    end
  end
  handle_asynchronously :fb_lint_me

  def publish_to_timeline token=nil, with_tags=true
    ### publish dive action to user's timeline.
    ### fbtoken if not nil will override the user's fb_token
    if(token.nil? && self.user.fbtoken.nil?) then raise DBTechnicalError.new "No FB Token" end
    if(self.privacy == 1)  then raise DBTechnicalError.new "Cannot push to timeline a dive that is not public" end
    #require 'faraday'
    require 'curb'

    if @user.nil? then @user = self.user end ## needed to get user's SI/Imperial prefs
    ac= ApplicationController.new ## need helper methods

    if token.nil?
      tk = self.user.fbtoken
    else
      tk = token
    end


    ##if graph_id is set, let's delete the entry

    if !self.graph_id.nil?
      headers = {
        'method' => 'delete',
        'access_token' => tk
      }
      res = Curl.post("https://graph.facebook.com/v2.0/#{self.graph_id}", headers)
      self.graph_id = nil
      self.save
    end



    # POST request -> logging in
    buddylist = self.buddies.map(&:nickname).join(",")
    data = ''
    fb_buddies = self.buddies.to_ary.reject do |b| b.fb_id.nil? end .map(&:fb_id) rescue []
    headers = {
      'access_token' => tk,
      'client_id' => FB_APP_ID.to_s,
      'client_secret' => FB_APP_SECRET.to_s,
      'dive' => "#{self.user.fullpermalink(:canonical)}/#{self.id}",
      'tags' => fb_buddies.join(","),
      'start_time'=> self.time_in.iso8601.to_s,
      'expires_in' => (self.duration*60).to_s,
      'image' => self.thumbnail_image_url
     # 'fb:explicitly_shared' => 'true' ##to add when action is validated
    }
    headers.except! 'tags' unless with_tags
    logger.debug "Publishing to OpenGraph with headers: " + headers.to_json
    #res = Koala::HTTPService.make_request 'https://graph.facebook.com/me/diveboard:log', headers, "post", headers
    #conn = Faraday.new(:url => 'https://graph.facebook.com') do |faraday|
    #  faraday.request  :url_encoded             # form-encode POST params
    #  faraday.response :logger                  # log requests to STDOUT
    #  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    #end

    #res = conn.post '/me/diveboard:log', headers
    res = Curl.post("https://graph.facebook.com/v2.0/me/diveboard:log", headers)

    if res.response_code == 200
      self.graph_id = JSON.parse(res.body_str)["id"].to_i
      self.save
      return true
    elsif res.response_code == 500 && begin JSON.parse(res.body_str)["error"]["code"] == 1611153 rescue false end
      logger.debug "Entry exists already: #{res.body_str.to_s}"
      begin
        self.graph_id = JSON.parse(res.body_str)["error"]["message"].match(/\ ([0-9]+)$/)[1]
        self.save
      rescue
        logger.debug "Could not create read the id of the graph entry"
      end
      return true

    #Failure due to user not allowing tags. Retrying without tags
    elsif begin JSON.parse(res.body_str)["error"]["code"] == 200 && JSON.parse(res.body_str)["error"]["error_subcode"] == 1610007 rescue false end
      logger.warn "Failed to publish on timeline with buddies tags"
      self.publish_to_timeline_without_delay token, false if with_tags

    else
      logger.debug "Could not create the OG entry: "+ res.body_str.to_s
      begin
        raise DBArgumentError.new "Could not create the OG entry for dive", dive_id: self.id, reply: res.body_str
      rescue
        LogMailer.report_exception $!, "dive #{self.id} - Could not create the OG entry: #{res.body_str}"
        raise $!
      end
    end
  end
  handle_asynchronously :publish_to_timeline

  def delete_timeline_entry

  end

  def featured_picture_thumbnail
    return featured_picture.thumbnail unless featured_picture.nil?
  end

  def profile_ref
    return nil if self.uploaded_profile_id.nil?
    "#{self.uploaded_profile_id},#{self.uploaded_profile_index}"
  end

  def profile_ref=(val)
    if val.nil? then
      ProfileData.delete_all(:dive_id => self.id)
      self.uploaded_profile_id = nil
      self.uploaded_profile_index = nil
      self.touch
    else
      data = val.match /^([0-9]+),([0-9]+)$/
      raise DBArgumentError.new "Profile reference is not correctly formatted", data: val if data.nil?
      raise DBArgumentError.new "Uploaded profile id is not valid", id:data[1] if UploadedProfile.where(:id => data[1].to_i).count == 0
      log = Divelog.new
      log.from_uploaded_profiles(data[1].to_i)
      raise DBArgumentError.new "Index is not valid within uploaded profile", index: data[2], id: data[1] if log.dives[data[2].to_i].nil?
      log.toDiveDB(data[2].to_i, self)
      self.uploaded_profile_id = data[1].to_i
      self.uploaded_profile_index =  data[2].to_i
      self.touch
    end
  end

  def delete_if_unlinked_to_user
    return if self.id == 1
    begin
      return if @being_destroyed
    rescue
      @being_destroyed = false
    end
    begin
      User.find(self.user_id)
    rescue
      @being_destroyed = true
      self.destroy
    end
  end

  def enforce_spot_moderation
    Rails.logger.debug "changed : #{self.changed_attributes}"
    return if self.spot_id == 1 # do not moderate default spot
    return unless self.changed_attributes.include? 'spot_id'
    return if prevent_enforce_spot_moderation

    begin
      spot_curs = self.spot
      spot_fwd_stack = [self.spot_id]
      counter = 0
      deja_vu = {}
      while !spot_curs.moderate_id.nil? do

        counter += 1
        if counter > 1000
          raise DBArgumentError.new "Counter 1 on dive.rb enforce_spot_moderation reached 1000 - this probably sucks"
        end
        next if deja_vu[spot_curs.id] ## try and prevent while(1)
        deja_vu[spot_curs.id] = true

        moderate_id = spot_curs.moderate_id
        spot_fwd_stack.push moderate_id
        Dive.where(:user_id => self.user_id).where(:spot_id => moderate_id).map {|d|
          next if d.id == self.id  # since we haven't saved the dive yet, it still has the old spot_id, thus creating a loop
          next if d.spot_id == self.spot_id
          d.spot_id = self.spot_id
          d.prevent_enforce_spot_moderation = true
          d.save
        }
        spot_curs = Spot.find(moderate_id)
      end
      counter = 0
      deja_vu={}
      while spot_fwd_stack.count > 0 do
        Rails.logger.debug "spot_fwd_stack: #{spot_fwd_stack.to_s}"
        counter += 1
        if counter > 1000
          raise DBArgumentError.new "Counter 2 on dive.rb enforce_spot_moderation reached 1000 - this probably sucks"
        end
        Rails.logger.debug "enforce_spot_moderation spot_fwd_stack.count : #{spot_fwd_stack.count}"
        fwd_spot_id = spot_fwd_stack.pop

        next if deja_vu[fwd_spot_id] ## try and prevent while(1)
        deja_vu[fwd_spot_id] = true

        Spot.where(:moderate_id => fwd_spot_id).map {|s| spot_fwd_stack.push s.id}
        Dive.where(:user_id => self.user_id).where(:spot_id => fwd_spot_id).map {|d|
          next if d.spot_id == self.spot_id
          d.spot_id = self.spot_id
          d.prevent_enforce_spot_moderation = true
          d.save
        }
      end
    rescue
      NotificationHelper.mail_background_exception $!, "Error while trying to enforce_spot_moderation on dive ##{self.id}"
    end
  end

  alias :active_changed? :changed?
  def changed?
    return self.active_changed? || @require_lint || false #or false to prevent returning nil
  end

  def send_to_dan!
    DanFormHelper.send_to_dan(self, dan_data)
  end

  def send_to_dan=(arg)
    self.send_to_dan!
  end

  def send_to_dan
    !self.dan_data_sent.nil?
  end

  def trip_name=(name)
    if name.blank? then
      self.trip_id = nil
    else
      trip = Trip.where(:user_id => self.user_id, :name => name).first
      if trip.nil? then
        trip = Trip.create(:user_id => self.user_id, :name => name)
      end
      self.trip_id = trip.id
    end
  end

  def trip_name
    return nil if trip.nil?
    return trip.name
  end

  def permalink
    return nil if self.id.nil?
    "#{user.permalink}/#{shaken_id}" rescue nil
  end
  def shaken_id
    return nil if self.id.nil?
    "D#{Mp.shake(self.id)}"
  end

  def fullpermalink option=nil
    return nil if permalink.nil?
    HtmlHelper.find_root_for(option).chop+permalink
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "D"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end

  def raw_profile=profile
    ProfileData.transaction do
      raw_profile.each &:destroy
      write_attribute(:raw_profile, profile)
    end
  end

  def update_disqus_comments msg
    ## will grab the disqus comment of the dive and save it
    DisqusComments.update_comment self, msg
  end
  handle_asynchronously :update_disqus_comments

  def update_fb_comments
    ## will grab the FB comment of the dive and save it
    ## dive comment link : https://www.diveboard.com/ksso/D25AZIW
    require 'curb'
    comment_link = self.fullpermalink(:canonical)
    fburl = "http://graph.facebook.com/v2.0/comments?id=#{comment_link}"
    res = Curl.get(fburl)
    if res.response_code == 200
      FbComments.update_fb_comments self, res.body_str
    end
  end
  handle_asynchronously :update_fb_comments

  def update_fb_like
    FbLike.get self
  end
  handle_asynchronously :update_fb_like


  ##
  ## Dive signature
  ##
  ##
  ##

  def request_shop_signature force=false
    raise DBArgumentError.new "Dive has no shop to ask signature from" if self.shop.nil?
    shop_sign = self.signatures.where("signby_type = '#{self.shop.class.to_s}'").where("signby_id = '#{self.shop.id}'")
    raise DBArgumentError.new "Dive already signed" if !shop_sign.where("signed_date is not NULL").empty?
    if !force
      raise DBArgumentError.new "Dive already rejected" if !shop_sign.where("rejected = 1").empty?
    end
    if !shop_sign.empty?
      s = shop_sign.pop
      shop_sign.each {|e| e.destroy}
      s.rejected = false
      s.request_date = Time.now
      if !s.notified_at.nil? &&  (Time.now - s.notified_at) > 5.days
        Rails.logger.debug  "Shop was already notified but user requested again and it was over 5 days ago so we'll notify again"
        s.notified_at = nil
      elsif !s.notified_at.nil?
        Rails.logger.debug  "Shop was already notified under 5 days ago"
        raise DBArgumentError.new "Shop was already notified less than 5 days ago - you need to wait until to try again", until: ((s.notified_at + 5.days).to_date.to_s)
      end
      s.save
    else
      s = Signature.create({
        #dive_id: self.id,
        signby_type: self.shop.class.to_s,
        signby_id: self.shop.id,
        request_date: Time.now
      })
      self.signatures << s
    end
    #self.reload  ## cannot reload if it hasn't been savc....
  end

  def shop_signature
    return nil if self.shop.nil?
    self.signatures.where(:signby_type => self.shop.class.to_s).where(:signby_id => self.shop.id).first
  end

  def signatures_confirmed
    return self.signatures.reject {|e| e.status != :signed}
  end

  def request_shop_signature=(val)
    ## used by API to generate requests - notably on bulk
    begin
      Rails.logger.debug("Requesting signature from shop with val #{val}")
      self.request_shop_signature
    rescue
      Rails.logger.debug "Couldn't sign koz #{$!.message}"
    end
  end


  def dive_reviews=(list_stars)
    if list_stars.class.to_s == "String"
      list_stars = JSON.parse(list_stars)
    end
    ## gets a hash of list stars and saves it
    l = Media.select_values_sanitized('select id from dive_reviews where dive_id = :dive_id AND name NOT IN (:list)', :dive_id=>self.id, :list=>list_stars.keys)
    if l.size() == 0 then
      DiveReview.where(:dive_id=>self.id).destroy_all
    end
    DiveReview.where(:id=>l).destroy_all
    list_stars.each do |cle, val|
      begin
        review = DiveReview.where(:dive_id => self.id, :name => cle).first
        if !review.nil? then
          review.update_attribute :mark, val
        elsif review.nil? then
          DiveReview.create :dive_id => self.id, :name => cle, :mark => val
        end
      rescue
        raise $!
      end
    end
  end

  def dive_reviews_api
    r={}
    self.dive_reviews.each {|e| r[e.name] = e.mark }
    return r
  end

  def review_summary
    dive_reviews = self.dive_reviews
    total = 0.0
    count = 0.0

    if dive_reviews.count == 0
      return nil
    end
    dive_reviews.each do |dive_review|
      return dive_review.mark if dive_review.name == 'overall'
      if dive_review.name != 'difficulty'
        total += dive_review.mark
        count += 1.0
      end
    end
    return total / count
  end
end
