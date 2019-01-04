require 'delayed_job'
require 'open-uri'

class Spot < ActiveRecord::Base
  extend FormatApi



  ##We do not want spots that are outdated
  default_scope where("not(spots.flag_moderate_private_to_public is false and spots.private_user_id is null)")
  ## must match def self.instantiate(record)


## IMPORTANT
## To ensure db coherence EVERY CREATED SPOT MUST BE VALIDATED
## thus unless it's coming from moderation process, every single spot
## will belong to its maker and be flagged to moderate
## only after validation can it get searchable
##
## flag_moderate_private_to_public defines the spot states
## nil <= it's a PUBLIC SPOT
## true <= it's a PRIVATE SPOT NOT YET MODERATED
## false <== it's a private spot that will NOT BE MODERATED
## false and private_user_id empty <= it's been merged and should be disregarded

## redirect_id is not nil <= spot has been merged into redirect_id and is DISABLED

## moderate_id is not nil <= it's a declared update of the spot #moderate_id


  #has_and_belongs_to_many :dives
  has_many :dives, :class_name => 'Dive'
  alias :dive_ids :dife_ids
  has_many :users, :through => :dives, :uniq => true
  belongs_to :country
  belongs_to :location
  belongs_to :wiki
  has_many :shops, :through => :dives, :uniq => true

  #belongs_to :wiki  ## that's a bit abusive ... but kinda true :)


  #validates that lat/long/zoom have been set - if not a spot is NOT defined
  validates :name, :exclusion => { :in => [nil], :message => "name cannot be nil"}

  #before_validation :enforce_case
  before_save :enforce_case, :check_country_bounds_if_needed, :check_country
  before_create :mark_to_moderate
  after_save :update_habtm    #, :cache_static_map ## not sure it's a good idea...


  cattr_accessor :userid  ## this defines the current user context


  define_format_api :public => [
        :id, :shaken_id, :country_name, :country_code, :country_flag_big, :country_flag_small,
        :within_country_bounds, :location_name, :permalink, :fullpermalink, :permalink,
        :staticmap,
        {
          :name => Proc.new {|s| s.name.titleize},
          :lat => Proc.new do |s|  begin s.lat.to_f rescue nil end end,
          :lng => Proc.new do |s|  begin s.long.to_f rescue nil end end
        }],
      :private => [],
      :mobile =>[:zoom, {
        :private_shaken_id => Proc.new do |s|  if !s.private_user_id.nil? then begin "U#{Mp.shake(s.private_user_id)}" rescue nil end else nil end end
        }],
      :search_light => [
        :score, :area_name, :public_dive_count, :dive_count, :user_count,
        :flag_moderate_private_to_public,
        :average_visibility, :average_current, :average_temp_bottom, :average_temp_surface, :average_depth,
        {
          :thumbnail => Proc.new {|p| p.best_pic.thumbnail rescue nil },
          :large => Proc.new {|p| p.best_pic.large rescue nil},
          :staticmap => '',
          :dive_ids => Proc.new do |s| begin (s.dives.reject do |d| d.privacy==1 end).map &:id rescue [] end end,
          :user_ids => Proc.new do |s| begin (s.dives.reject do |d| d.privacy==1 end).map(&:user_id).uniq rescue [] end end,
          :shop_ids => Proc.new {|p| p.shop_ids.reject &:nil?},
          :countryblob => Proc.new do |s|  begin if s.country.id == 1 then nil else s.country.blob end rescue nil end end,
          :locationblob => Proc.new do |s|  begin if s.location.id == 1 then nil else s.location.blob end rescue nil end end
        }],
      :search_full => [ :flag_moderate_private_to_public, :wiki_html, {
                      :has_wiki_content => Proc.new {|p| p.wiki.nil?},
                      :best_pics => Proc.new {|p| p.best_pics.to_api :public}
                    }],
      :search_full_server => [
        :average_current, :average_depth, :average_temp_bottom, :average_temp_surface, :average_visibility, :country_flag_small, :country_name, :dive_count, :id, :lat, :lng, :location_name, :permalink, :shaken_id, :user_count,
        {
          :shops => lambda {|s| s.shops.joins(:user_proxy).where('users.id is not null').limit(20).map {|shop| shop.to_api :search_full_server_l2}},
          :users => lambda {|s| s.users[0..20].map {|u| u.to_api :search_full_server_l1}},
          :dives => lambda {|s| (s.dives.reject do |d| d.privacy==1 end )[0..20].map {|d| d.to_api :search_full_server_l1}},
          :pictures => lambda {|s| s.pictures[0..20].map {|d| d.to_api :public}}
        }],
      :search_full_server_l1 => [:country_flag_small, :country_name, :id, :lat, :lng, :location_name, :name],
      :search_full_server_l2 => [:id, :name ],
      :moderation => [:country_id, :location_id, :moderate_id, :private_user_id, :verified_user_id, :verified_date, :created_at, :updated_at, :zoom, :description, :staticmap]

  define_api_includes :private => [:public], :mobile => [:public], :search_light => [:public], :search_full => [:public], :moderation => [:public, :search_light, :search_full], :search_full => [:search_light]
  define_api_private_attributes :private_user_id, :verified_user_id, :verified_date

  define_api_updatable_attributes %w( name country_id country_name country_code lat lng long zoom moderate_id)
  define_api_updatable_attributes_rec 'location' => Location


  def is_private_for?(options={})
    @api_user = options[:caller] ## we need to know who's allegedly doing stuff
    return false if self.id == 1
    return false if options[:caller].nil?
    return true if options[:action]==:create
    return true if options[:caller].admin_rights > 2
    return false
  end

  ##Only create a new spot when it's really new when it makes sense
  def create
    begin
      if self.id.nil? then
        Rails.logger.debug "trying to dedup Spot creation on name #{self.name}"
        epsilon = 0.00001 ## about 1 meter
        ##searching a similar public spot
        if !self.private_user_id.nil?
          themaker_id = self.private_user_id
        elsif !@api_user.nil?
          themaker_id = @api_user.id
        elsif !@user.nil?
          themaker_id = @user.id
        end

        Rails.logger.debug "themaker is #{themaker_id}"
        same_spot_list = []
        same_spot_list.push Spot.where(
          :name => self.name,
          :country_id => self.country_id,
          :private_user_id => nil,
          :zoom => self.zoom,
          :location_id => self.location_id
          ).where(
          "spots.lat between #{self.lat.to_f-epsilon} and #{self.lat.to_f+epsilon}"
          ).where(
          "spots.long between #{self.long.to_f-epsilon} and #{self.long.to_f+epsilon}"
          ).where("flag_moderate_private_to_public is NULL")
        Rails.logger.debug "Found #{same_spot_list.count} public spots"
        ##searching a similar private spot
        same_spot_list.push Spot.where(
          :name => self.name,
          :country_id => self.country_id,
          :private_user_id => themaker_id,
          :zoom => self.zoom,
          :location_id => self.location_id
          ).where(
          "spots.lat between #{self.lat.to_f-epsilon} and #{self.lat.to_f+epsilon}"
          ).where(
          "spots.long between #{self.long.to_f-epsilon} and #{self.long.to_f+epsilon}"
          )
        same_spot_list.flatten!
        Rails.logger.debug "Found #{same_spot_list.count} public+private spots"

        old = same_spot_list.first
        ##TODO moderate if more than one answer...
        if !old.nil? then
          Rails.logger.debug "Loading #{old.id}:"
          self.id = old.id
          self.reload
          @new_record = false ## I'm lying
          return self.id
        else
          Rails.logger.debug "Creating a new spot - adding in the moderation queue"
          raise DBArgumentError.new "Creating a new spot but we have no owner!" if self.private_user_id.nil? && themaker_id.nil?
          if self.private_user_id.nil?
            self.private_user_id = themaker_id
            self.flag_moderate_private_to_public = true
          end
        end
      end
    rescue
      Rails.logger.debug "Deduplication of Spot failed with "+$!.message
    end
    super()
  end

  def zoom=(val)
    if val < 6
      write_attribute(:zoom, 6)
    elsif val >12
      write_attribute(:zoom, 12)
    else
      write_attribute(:zoom, val)
    end
  end

  def moderate_id=(val)
    if !val.nil?
      Spot.find(val)
    end
    #raise DBArgumentError.new "#{val} as moderate_id of #{self.id} is forbidden, already in the list" if self.build_moderation_chain.include? val
    ## the above needs to be allowed otherwise we can't bind children to parent during moderation...

    write_attribute(:moderate_id, val)
  end

  def flag_moderate_private_to_public=(val)
    if val.nil?
      raise DBArgumentError.new "Cannot set public a spot with a moderate_id" unless self.moderate_id.nil?
    end
    write_attribute(:flag_moderate_private_to_public, val)
  end

  def wiki userid=nil
     Wiki.get_wiki(self.class.to_s, self.id, userid)
  end

  def wiki_html userid=nil
    begin
      self.wiki(userid).data.html_safe
    rescue
      nil
    end
  end

  def backup
    ##makes a backup of the current object as a JSON string (will be used on the moderation thing to save our ass if we're a beat too fearless)
    o = JSON.parse(self.to_json)
    ## adding extra data
    o["extra"]={}
    o["extra"]["location_name"] = self.location.full_name unless self.location.nil?
    o["extra"]["country_name"] = self.country.cname unless self.country.nil?
    o["extra"]["dives"] = self.dives.map{|r| r.id} unless self.dives.empty?


    return o.to_json
  end


  def enforce_case
    self.name = self.name.titleize unless self.name.nil?
  end

  def fullcname
    return country.cname
  end


  def static_map_url
    zoomfix = (self.zoom) -2
    if zoomfix < 1 then
      zoomfix = 1
    end

    if cache_static_map
      return (HtmlHelper.lbroot "/map_images/map_#{self.id}.jpg?v=#{self.updated_at.to_i}")
    else
      return "https://maps.google.com/maps/api/staticmap?center=#{self.lat.to_f},#{self.long.to_f}&zoom=#{zoomfix}&size=128x128&maptype=hybrid&sensor=false&format=jpg&key=#{GOOGLE_MAPS_API}"
    end
  end

  def cache_static_map


    if File.exists?("public/map_images/map_#{self.id}.jpg")
      return true
    else
      zoomfix = (self.zoom) -2
      if zoomfix < 1 then
        zoomfix = 1
      end
      %x{curl -s -S -o "public/map_images/map_#{self.id}.jpg" "https://maps.google.com/maps/api/staticmap?center=#{self.lat.to_f},#{self.long.to_f}&zoom=#{zoomfix}&size=128x128&maptype=hybrid&sensor=false&format=jpg&key=#{GOOGLE_MAPS_API}"}
      self.touch
      return check_valid_static_map
    end
  end

  def check_valid_static_map
    error_static_maps = ["1593c0378c0acc8eff44ad54f65702b0dde4311d", "379c72f9f94b115d78048a150aee3e26f239d4d2"]
    return false unless File.exists?("public/map_images/map_#{self.id}.jpg")
    if error_static_maps.include? %x{shasum "public/map_images/map_#{self.id}.jpg"}.split(" ")[0]
      begin
        File.delete("public/map_images/map_#{self.id}.jpg")
        self.touch
      rescue
        Rails.logger.debug "Could not delete map for spot #{self.id}"
      end
      return false
    end
    return true
  end

  def pinned_map_url x,y

    if self.lat == 0 && self.lng == 0 then
      return "https://maps.google.com/maps/api/staticmap?center=#{self.lat.to_f},#{self.long.to_f}&zoom=0&size=#{x}x#{y}&maptype=hybrid&sensor=false&format=jpg&key=#{GOOGLE_MAPS_API}"
    end

    zoomfix = (self.zoom) -2
    if zoomfix < 1 then
      zoomfix = 1
    end

    return "https://maps.google.com/maps/api/staticmap?center=#{self.lat.to_f},#{self.long.to_f}&zoom=#{zoomfix}&size=#{x}x#{y}&maptype=hybrid&markers=icon:https://www.diveboard.com/img/marker.png%7C#{self.lat.to_f},#{self.long.to_f}&sensor=false&format=jpg&key=#{GOOGLE_MAPS_API}"
  end

  def update_habtm
    ## this updated the habtm for a given spot
    self.country.locations << self.location unless self.location.nil? || self.country.nil?
  end


  def self.find_or_create_by_name(site, place, user_id)
    ## used for trying to figure out spots on bulk import
    #First search for site in the database
    logger.debug "SPOT.find_or_create_by_name on site: #{site|| ""}, place: #{place || ""} , for user : #{user_id}"
    spot_found = Spot.where("lower(name) in (:name)", {:name => site.to_s.downcase.split(/ *, */)}).where("flag_moderate_private_to_public IS NULL OR flag_moderate_private_to_public = #{user_id}")

    list_coma = (place || site).downcase.split(/ *, */)
    Rails.logger.debug list_coma
    country_found = Country.where("lower(cname) in (:cname)", {:cname => list_coma})
    location_found = Location.where("lower(name) in (:name) or lower(name2) in (:name) or lower(name3) in (:name2)", {:name => list_coma})

    Rails.logger.debug "Name analysed : #{list_coma}"
    Rails.logger.debug "Found : #{spot_found.count} Spots, #{country_found.count} countries, #{location_found.count} locations"

    real_spot = nil

    if spot_found.count > 0 then
      spot_found.each { |spot|
        country_ok = (place || site).downcase.match( spot.country.cname.downcase )
        location_ok = (place || site).downcase.match( spot.location.name.downcase)

        # If we found a spot for which both the location and the country look ok, then we take it !
        if country_ok && location_ok then
          real_spot = spot
        end

        # If we found a spot for which the location looks ok,
        # and there doesn't seem to be any country mentionned, then we bet it's ok...
        if location_ok && !country_ok && country_found.count==0 then
          real_spot = spot
        end
      }
    end

    return real_spot unless real_spot.nil?

    # 2/ if not found create a new personal spot
    if real_spot.nil? then
      new_spot = nil

      Spot.transaction {
        new_location = Location.find(1)
        new_country = Country.find(1)

        # If we found both a correct location and country, then let's reuse that location
        if country_found.count > 0 && location_found.count > 0 then
          Rails.logger.debug "Checking if correct location"
          location_found.each {|location|
            Rails.logger.debug "Checking with location '#{location.name}' (#{location.id}) - country '#{location.country.cname}'"
            if (place || site).downcase.match location.country.cname.downcase then
              Rails.logger.debug "Using existing location : #{location.name} (#{location.id})"
              new_location = location
              new_country = location.country
            end
          }

          Rails.logger.debug new_location.id
          # If no good location was found then we need to create one
          if new_location.id == 1 && !place.nil? && !site.nil? then

            location_name = place

            new_country = country_found.first
            l = place.split(/ *, */)
            l.reject! {|t| t =~ /#{new_country.cname}/i}
            location_name = l.join(', ')

            if location_name != "" then
              new_location = Location.create( :name =>  location_name, :country_id => new_country.id)
            end

          end

        # If we found a correct location and no country mentionned, we bet it's the correct location
        elsif location_found.count > 0 && country_found.count == 0 then
          new_location = location_found.first
          new_country = location_found.first.country

        #else if it's possible to create the a separate location
        elsif !place.nil? && !site.nil? then

          location_name = place

          if country_found.count > 0 then
            new_country = country_found.first
            l = place.to_s.split(/ *, */)
            l.reject! {|t| t =~ /#{new_country.cname}/i}
            location_name = l.join(', ')
          end

          if location_name != "" then
            new_location = Location.create(:name =>  location_name, :country_id => new_country.id)
          end

        # else we only have the country, let's take it anyway and put everything else as the spot name
        elsif country_found.count > 0 then
          new_country = country_found.first

        end

        #Now create the spot
        spot_name = site
        Rails.logger.debug "sn: #{spot_name}"
        if site.nil? || place.nil? then
          l = spot_name.to_s.split(/ *, */)
          l.reject! {|t| t =~ /#{new_location.name}/i } unless new_location.name.nil? || new_location.name == ""
          l.reject! {|t| t =~ /#{new_country.cname}/i } unless new_country.cname.nil? || new_country.cname == ""
          spot_name = l.join(', ')
        end
        Rails.logger.debug "sn: #{spot_name}"
        spot_lat = 0
        spot_lng = 0

        Rails.logger.debug ":name => #{spot_name}, :lat => #{spot_lat}, :long => #{spot_lng}, :zoom => #{0}, :precise => #{false}, :location_id => #{new_location.id}, :country_id => #{new_country.id}, :private_user_id => #{user_id}, :flag_moderate_private_to_public => true)"
        new_spot = Spot.create( :name => spot_name, :lat => spot_lat, :long => spot_lng, :zoom => 0, :precise => false, :location_id => new_location.id, :country_id => new_country.id, :private_user_id => user_id, :flag_moderate_private_to_public => true, :from_bulk => true)
        new_spot.save if new_spot.id.nil? || new_spot.changed? || new_spot.new_record?
        new_spot.fetch_rough_coords_from_google!
      }
      return new_spot
    end
  end


  def fetch_rough_coords_from_google!
    spot_lat = 0.0
    spot_lng = 0.0

    begin
      address = self.name
      if self.location.id > 1 then
        address += " " + self.location.name
      end
      if self.country.id > 1 then
        address += " " + self.country.name
      end
      uri_val = URI.escape("https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{address}&key=#{GOOGLE_MAPS_API}")
      uri = URI.parse(uri_val)
      logger.debug "Calling google's geoname with URL #{uri_val}"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = false
      request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
      response = http.request(request)
      data = response.body
      results = JSON.parse(data.force_encoding("UTF-8"))
      #results = JSON.parse(data)
      raise DBArgumentError.new "No result to Geocode search" if results["results"].length == 0

      spot_lat = results["results"][0]['geometry']['location']['lat']
      spot_lng = results["results"][0]['geometry']['location']['lng']
      #let's find the country now
      results["results"][0]["address_components"].each do |c|
        if c["types"].include? "country"
          begin
            new_country = Country.find_by_cname c["long_name"]
          rescue
          end
          break
        end
      end

    rescue
      logger.debug "Google Geoname search failed #{$!.message}"
    end

    spot_lat = 0 if spot_lat.nil?
    spot_lng = 0 if spot_lng.nil?

    if spot_lng == 0 && spot_lat == 0
      ##last resort
      if location.id > 1 then
        spot_list = Spot.where(:location_id => self.location.id)
        spot_lat = spot_list.average(:lat)
        spot_lng = spot_list.average(:long)
      elsif country.id > 1 then
        spot_list = Spot.where(:country_id => self.country.id)
        spot_lat = spot_list.average(:lat)
        spot_lng = spot_list.average(:long)
      end
    end


  end
  handle_asynchronously :fetch_rough_coords_from_google!


  def dive_albums
    self.dives.map do |d| d.picture_album_pictures end .flatten.uniq
  end

  def picture_ids
    self.pictures.map(&:id)
  end

  def pictures
    self.dive_albums.map(&:picture).flatten.uniq.reject(&:nil?)
  end

  def best_pic_ids=l
    if l.is_a?(Array) then
      write_attribute(:best_pic_ids, JSON.unparse(l))
    else
      write_attribute(:best_pic_ids, nil)
    end
  end

  def best_pic_ids
    return JSON.parse(read_attribute(:best_pic_ids)) rescue []
  end

  def best_pics
    Picture.where :id => best_pic_ids
  end

  def best_pic
    best_pic_ids.each do |id|
      return Picture.find(id) rescue next
    end
  end
  alias :picture :best_pic

  def update_best_pics!
    great = []
    covers = []
    max_pics = 21

    self.dives.order('created_at desc').each do |dive|
      pics = dive.pictures
      covers.push pics.first.id if pics.first && pics.first.elligible_best_pic && covers.count < max_pics
      pics.each do |p|
        if p.great_pic && p.elligible_best_pic then
          great.push p.id
          break if great.count >= max_pics
        end
      end
      break if great.count >= max_pics
    end

    update_attributes :best_pic_ids => (great + covers)[0..(max_pics-1)]
  end

  def update_score!
    return @computed_score if @computed_score
    initial_score = score
    s = 0
    self.public_dives.each do |dive|
      pics = dive.pictures
      pics.each do |p|
        s += 10 and break if p.great_pic
      end
      s += 5 if pics && pics.count > 0
      s += 2 if pics && pics.count > 6
    end
    s += [ 30, self.public_dive_ids.count ].min / 5
    s += [ 20, self.public_user_ids.count ].min / 2
    s -= 10 if self.name.blank?
    s -= 5 if self.country.nil? || self.country.name.blank?
    s -= 5 if self.location.nil? || self.location.name.blank?
    update_attributes :score => s unless s == initial_score
    @computed_score = s
    return s
  end

  def lng
    return self.long
  end

  def lng=(val)
    self.long = val
  end

  def country_name
    return self.country.name unless self.country.nil?
  end

  def country_name=name
    self.country = GeonamesAlternateName.joins(:geonames_core).where(:name => name, :geonames_cores => {:feature_code => 'PCLI'}).first.geonames_core.country rescue Country.find(1)
  end

  def country_code
    return self.country.ccode unless self.country.nil?
  end

  def country_code=code
    self.country = Country.where(:ccode => code).first
  end

  def location_name
    return self.location.full_name unless self.location.nil?
  end

  def staticmap
    return self.pinned_map_url 128, 128
  end

  def area_name
    [self.country, self.location].reject(&:nil?).map(&:name).reject(&:blank?).join(", ") rescue ''
  end

  def dive_count
    self.dive_ids.count
  end

  def public_dive_count
    self.dives.reject {|d| d.privacy == 1} .count
  end

  def public_dive_ids
    self.public_dives.map &:id
  end

  def public_dives
    self.dives.reject {|d| d.privacy == 1}
  end

  def public_user_ids
    self.public_dives.map(&:user_id).uniq
  end

  def user_count
    self.user_ids.to_ary.count
  end

  def picture_count
    self.picture_ids.count
  end

  def country_flag_big
    return self.country.flag_big unless self.country.nil?
  end

  def country_flag_small
    return self.country.flag_small unless self.country.nil?
  end

  def merge_into mod_id
    ##will merge self spot stuff into Spot.mod_id and delete itself
    if self.id != mod_id
      mybackup = self.backup
      new_spot = Spot.find(mod_id) ## will raise if no spot
      if new_spot.moderate_id == self.id
        ModHistory.create(:obj_id => new_spot.id, :table => self.class.to_s, :operation => MOD_UPDATE, :before => {:moderate_id => new_spot.moderate_id}.to_json, :after => {:moderate_id => nil}.to_json)
        new_spot.moderate_id = nil
        new_spot.save

      end

      ## update dives from moderate to original spot
      self.dives.each do |dive|
        ## Save the Dive data
        Rails.logger.debug "Updating spot_id for dive #{dive.id}"
        dive_backup = dive.to_api(:public, :private => true).to_json
        dive.spot_id = mod_id
        dive.save
        ModHistory.create(:obj_id => dive.id, :table => dive.class.to_s, :operation => MOD_UPDATE, :before => dive_backup, :after => dive.to_api(:public, :private => true).to_json)
      end




      ## updates spots pointing to me
      ## we must NOT loose those links
      Spot.where(:moderate_id => self.id).each do |s|
        s.moderate_id = mod_id
        s.save
      end



      ##kill me
      new_spot.reload
      Rails.logger.debug "Finishing up the merge"
      self.flag_moderate_private_to_public = false;
      self.private_user_id = nil;
      self.redirect_id = mod_id
      self.save
      ModHistory.create(:obj_id => self.id, :table => self.class.to_s, :operation => MOD_MERGE, :before => mybackup, :after => self.backup)
      #ModHistory.create(:obj_id => self.id, :table => self.class.to_s, :operation => MOD_DELETE, :before => self.backup, :after => nil)
      #self.delete ## me mark as alias instead of deleting
      #self.alias_id = mod_id
      #self.save
    else
      Rails.logger.debug "No point in merging in myself - I know who I am"
    end

  end

  def merge_into_self spot_ids, user_id
    spots = Spot.where(:id => spot_ids).to_ary
    spots_private_user_ids = spots.map(&:private_user_id).uniq

    Spot.transaction do
      if self.private_user_id.nil? then
        spots.each do |s|
          s.merge_into self.id
        end
      elsif spots_private_user_ids.length == 1 && spots_private_user_ids.first == self.private_user_id then
        spots.each do |s|
          s.merge_into self.id
        end
      else
        # Make sure the whole moderation chain is merged... actually, only the original spots should be checked...
        if !self.moderate_id.nil? then
          sids = self.build_moderation_chain - spots.map(&:id) - [self.id]
          Rails.logger.debug "Checking if moderate_id can be set to nil: #{sids}"
          if sids.count == 0 then
            Rails.logger.debug "Allowing moderate_id to be set to nil"
            self.moderate_id = nil
            self.save!
          end
        end

        #we should not validate but only make public, then merge
        self.flag_moderate_private_to_public = nil
        self.private_user_id = nil
        self.save!
        spots.each do |s|
          s.merge_into self.id
        end
      end
    end
  end
  handle_asynchronously :merge_into_self

  def validate_public duplicate_list=[], validator_user_id
    ## will sign spot for @user at current time
    ## and merge duplicated into it
    ## and ensure that spots that were pointing to and from it keep coherent pointers

    Rails.logger.debug "Validate_public on #{self.id} with dupes #{duplicate_list.to_s} and validator #{validator_user_id.to_s}"


    mybackup=self.backup
    self.verified_date = Time.now
    self.verified_user_id = validator_user_id

    ##manage the sons & ancestors
    ## we need to remove the bindings with sons and ancetors here since either they are in duplicate list or are different
    self.remove_from_moderation_chain


    ## Spot will now be "made public"
    self.flag_moderate_private_to_public = nil
    self.private_user_id = nil
    self.save!

    ##manage duplicates from list
    duplicate_list.each do |s|
      begin
        target = Spot.find(s)
        target.merge_into self.id
        Rails.logger.debug "merged spot #{s} into #{self.id}"
      rescue
        Rails.logger.debug "Could not merge spot #{s} into #{self.id}: #{$!.message}"
      end
    end
    self.reload ## we'll be updating the dives count so need to reload
    ModHistory.create(:obj_id => self.id, :table => self.class.to_s, :operation => MOD_VALIDATE_MERGE, :before => mybackup, :after => self.backup)
  end

  def validate_private duplicate_list=[]
    ## will not sign the spot but keep it private and out of the validation
    ## process as it could not be identified
    ## and merge duplicated into it
    ## and update the owner_id

    owner_id = self.dives.map(&:user_id).first

    Rails.logger.debug "Validate_private on #{self.id} with dupes #{duplicate_list.to_s} and owner #{owner_id.to_s}"

    mybackup=self.backup
    self.remove_from_moderation_chain

    ## Spot will now be "disabled"
    self.verified_user_id = nil ## it can't be validated if it's private
    self.flag_moderate_private_to_public = false ## it's a private spot

    self.private_user_id = owner_id
    self.save!

    ##manage duplicates from list
    duplicate_list.each do |s|
      begin
        Spot.find(s).merge_into self.id
      rescue
        Rails.logger.debug "Could not merge spot #{s} into #{self.id}: #{$!.message}"
      end
    end
    ModHistory.create(:obj_id => self.id, :table => self.class.to_s, :operation => MOD_PRIVATE_MERGE, :before => mybackup, :after => self.backup)

    self.fix_owners
  end

  def fix_owners
    #checks if there is a moderate flag that only one user owns this spot
    #if false, will create duplicates of this spot for each owner
    return if self.id == 1 ## this one sux
    return if self.flag_moderate_private_to_public.nil?
    mydives = self.dives
    ownersid = mydives.map(&:user_id).uniq
    Rails.logger.debug "Found #{ownersid.count} owners for spot #{self.id}"
    if ownersid.count == 0
      self.private_user_id = nil
      self.save!
      return
    else
      self.private_user_id = ownersid.first
      Rails.logger.debug "Assigning user #{ownersid.first} to spot #{self.id}"
      self.save!
      self.reload
      ownersid.each_with_index do |uid, i|
        next if i == 0
        Rails.logger.debug "Duplicating spot #{self.id} for user #{uid}"
        newspot = self.duplicate
        newspot.private_user_id = uid
        newspot.save!
        Rails.logger.debug "Duplicating spot #{self.id} for user #{uid} into #{newspot.id} DONE"
        Rails.logger.debug "Will be checkking #{mydives.count} dives for updating"
        mydives.each do |d|
          if d.user_id == uid
            Rails.logger.debug "Updating spot on dive #{d.id} to #{newspot.id}"
            tdive = Dive.find(d.id)
            tdive.spot_id = newspot.id
            tdive.save!
          end
        end
      end
    end
  end

  def duplicate
    #This creates a new spot with no owner in the same moderation state and returns the new spot
    myattributes = self.attributes
    myattributes["moderate_id"]=nil
    myattributes["private_user_id"]=nil
    myattributes["best_pic_ids"]=nil
    newspot = Spot.new(myattributes)
    newspot.moderate_id = self.id ## wanna link to daddy
    newspot.save!
    return newspot
  end


  def remove_from_moderation_chain
    ##removes current spot from the moderation chain
    ## ensure sons link to ancestor ... or whatever makes sense
    my_main_backup = self.backup
    sons = Spot.where(:moderate_id => self.id)

    if self.moderate_id.nil?
      ancestor = nil
      Rails.logger.debug "spot has no ancestor"
      if sons.count >1
        sons.each_with_index do |s, i|
          mybackup = s.backup
          if i == 0
            #set first spot as origin
            parent = s.id ## this is the new paent id
            s.moderate_id = nil
            s.flag_moderate_private_to_public = true
            s.save!
          else
            s.moderate_id = parent
            s.flag_moderate_private_to_public = true
            s.save!
          end
          ModHistory.create(:obj_id => s.id, :table => self.class.to_s, :operation => MOD_CHAIN_UPDATE, :before => mybackup, :after => s.backup)

        end
      elsif sons.count == 1
        mybackup = sons.first.backup
        sons.first.moderate_id = nil
        sons.first.flag_moderate_private_to_public = true
        sons.first.save!
        ModHistory.create(:obj_id => sons.first.id, :table => self.class.to_s, :operation => MOD_CHAIN_UPDATE, :before => mybackup, :after => sons.first.backup)
      end
    else
      ancestor = Spot.find(self.moderate_id)
      Rails.logger.debug "spot has an ancestor"
      sons.each do |s|
        mybackup = s.backup
        s.moderate_id = ancestor.id
        s.save!
        ModHistory.create(:obj_id => s.id, :table => self.class.to_s, :operation => MOD_CHAIN_UPDATE, :before => mybackup, :after => s.backup)

      end
    end
    self.moderate_id = nil
    self.save
    ModHistory.create(:obj_id => self.id, :table => self.class.to_s, :operation => MOD_CHAIN_UPDATE, :before => my_main_backup, :after => self.backup)

  end


  def build_moderation_chain moderation_chain=[]
    ## returns a moderation chain of SPOT IDs sorted from the lowest id to highest id
    ## chances are lowest id is the origin of the chain

    ##loop detection
    if self.id.nil?
      ## case new spot not created
      if moderate_id.nil?
        return []
      end
    end

    return moderation_chain if moderation_chain.include? self.id

    ##add self
    moderation_chain.push self.id
    ##handle parents
    if !self.moderate_id.nil?
      begin
        s = Spot.find(self.moderate_id)
      rescue
        ## we lost the original spot
        Rails.logger.error "Spot #{self.id} was tagged as a moderate to #{self.moderate_id} which is not available anymore."
        self.moderate_id = nil
        self.save
        s = nil
      end
      if !s.nil?
        moderation_chain.push (s.build_moderation_chain(moderation_chain).flatten.uniq)
        moderation_chain= moderation_chain.flatten.uniq
      end
    end
    ##handle children
    if !self.id.nil? ##irrelevant for not saved spots
      sl = Spot.where(:moderate_id => self.id)
      sl.each do |s|
        moderation_chain.push (s.build_moderation_chain(moderation_chain).flatten.uniq)
        moderation_chain= moderation_chain.flatten.uniq
      end
    end

    ##return the object
    return moderation_chain.reject(&:nil?).sort
  end

  def permalink
    "#{self.location.permalink}/#{blob}"
  end
  def blob
    if name.blank?
      "unnamed-spot-#{shaken_id}"
    else
      "#{name.to_url}-#{shaken_id}"
    end
  end
  def fullpermalink option=nil
    HtmlHelper.find_root_for(option).chop+permalink
  end
  def shaken_id
    "S#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "S"
       i =  Mp.deshake(code[1..-1])
    else
       i = Integer(code.to_s, 10)
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      target = Spot.find(i)
      if !target.redirect_id.blank?
        return Spot.idfromshake(target.redirect_id) ## we follow the redirections recursively
      else
        return i
      end
    end
  end

  def check_country_bounds_if_needed
    k = self.changes.keys
    check_country_bounds if within_country_bounds.nil? || k.include?('lat') || k.include?('long') || k.include?('country_id')
  end

  def check_country_bounds
    wcb = false
    if self.country_id == 1 || self.country_id.blank?
      wcb = false
    else
      bounds = JSON.parse Country.find(country_id).nesw_bounds ## we need country.find as country may have changed
      if lat >= bounds["southwest"]["lat"] && lat <= bounds["northeast"]["lat"] && self.long >= bounds["southwest"]["lng"] && self.long <= bounds["northeast"]["lng"]
        wcb = true
      else
        ## let's try some more
        begin
          uri = URI.parse(URI.escape("http://ws.geonames.org/countryCode?lat=#{lat}&lng=#{long}"))
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
          response = http.request(request)
          data = response.body.match(/[A-Z]+/)[0]
          Rails.logger.debug "Got : #{data}"
          cn = Country.find_by_ccode data
          if self.country_id == cn.id
            wcb = true
          else
            wcb = false
          end
        rescue
          LogMailer.report_exception $!, "spot id: #{self.id} geocode call : #{uri.to_s} response: #{response}"
          wcb = false
        end
      end
    end
    ## TODO in rails 3.1 or higher self.update_columns('within_country_bounds', wcb )
    #ActiveRecord::Base.connection.execute "update `spots` set `within_country_bounds` = #{wcb ?1:0} where id = #{self.id}"
    self.within_country_bounds = wcb
    ## WARNING we must not use save here :) or we go through the callbacks again
    return true
  end

  def status
    return :public if flag_moderate_private_to_public.nil?
    return :awaiting_moderation if flag_moderate_private_to_public == true
    return :private if flag_moderate_private_to_public == false && !private_user_id.nil?
    return :disabled if flag_moderate_private_to_public == false && private_user_id.nil?
  end


  def is_visible_for? userid=nil
    ## decides wether a user with userid can access this spot (i.e. to add it to his dives)

      if self.flag_moderate_private_to_public.nil?
        return true
      end
      ##On a second thought we may not want those...
      #if s.flag_moderate_private_to_public == true && !s.dives.empty?
      #  sanitized_array.push s
      #  next
      #end
      if self.flag_moderate_private_to_public == true && !self.dives.empty?
        return true
      end
      if !userid.nil? && self.private_user_id == userid && !self.dives.empty?
        return true
      end
      return false
  end

  def basicfix00
    logger.debug "Fixing by averaging country's position"
    if self.lat == 0 && self.long == 0
     if self.location_id != nil?  && self.location_id != 1 then
        spot_list = Spot.where(:location_id => self.location_id)
        self.lat = spot_list.average(:lat)
        self.long = spot_list.average(:long)
        self.save
      end
    end

    if self.lat == 0 && self.long == 0
      if self.country_id != 1 then
        self.lat = ((self.country.bounds["northeast"]["lat"] +self.country.bounds["southwest"]["lat"])/2).to_f
        swl = self.country.bounds["southwest"]["lng"]
        nel = self.country.bounds["northeast"]["lng"]
        if nel<swl
          nel += 360
          avg = ((nel+swl)/2).to_f
          if avg < 180
            self.long = avg
          else
            self.long = -avg
          end
        else
          self.long = ((nel+swl)/2).to_f
        end
        self.save
      end
    end

  end

  def google_get_location
    if !self.lat.nil? and !self.lng.nil? and self.lat != 0 and self.lng != 0 then
      logger.debug "Trying to get location for spot #{self.id}"
  
      new_country = nil
      new_admin_l1 = nil
      new_admin_l2 = nil
      new_admin_l3 = nil
      new_formatted_address = nil
      new_locality = nil;
      new_poi = nil
  
      spot_lat = self.lat
      spot_lng = self.long
      uri_val = URI.escape("https://maps.googleapis.com/maps/api/geocode/json?sensor=false&key=#{GOOGLE_MAPS_API}&latlng=#{spot_lat},#{spot_lng}")
      uri = URI.parse(uri_val)
      logger.debug "Calling google's geoname with URL #{uri_val}"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
      response = http.request(request)
      data = response.body
      results = JSON.parse(data.force_encoding("UTF-8"))
      if results["results"].length == 0
        logger.debug " ZERO_RESULTS, trying with address bis"
        return
      end
      if results["results"].length == 0
        #nothing to do
        logger.debug "ZERO_RESULTS, Could not fix spot's position"
        return
      end
  
      #let's find the country now
      results["results"].each do |res|
        res["address_components"].each do |c|
          if c["types"].include? "country" and new_country.nil?
            new_country = c["long_name"]
          end
          if c["types"].include? "locality" and new_locality.nil?
            new_locality = c["long_name"]
          end
          if c["types"].include? "administrative_area_level_1" and new_admin_l1.nil?
            new_admin_l1 = c["long_name"]
          end
          if c["types"].include? "administrative_area_level_2" and new_admin_l2.nil?
            new_admin_l2 = c["long_name"]
          end
          if c["types"].include? "administrative_area_level_3" and new_admin_l3.nil?
            new_admin_l3 = c["long_name"]
          end
          if (c["types"].include? "park" or c["types"].include? "point_of_interest") and new_poi.nil?
            new_poi = c["long_name"]
          end
        end
      end
      
      name1 = nil
      name2 = nil
      name3 = nil
      if name1.nil? and !new_poi.nil? then
        name1 = new_poi
        new_poi = nil
      end
      if name1.nil? and !new_locality.nil? then
        name1 = new_locality
        new_locality = nil
      end
      if name1.nil? and !new_admin_l1.nil? then
        name1 = new_admin_l1
        new_admin_l1 = nil
      end
      if name1.nil? and !new_formatted_address.nil? then
        name1 = new_formatted_address
        new_formatted_address = nil
      end
      if name2.nil? and !new_locality.nil? then
        name2 = new_locality
        new_locality = nil
      end
      if name2.nil? and !new_admin_l1.nil? then
        name2 = new_admin_l1;
        new_admin_l1 = nil
      end
      if name2.nil? and !new_admin_l2.nil? then
        name2 = new_admin_l2
        new_admin_l2 = nil
      end
      if name3.nil and !new_admin_l1.nil? then
        name3 = new_admin_l1
        new_admin_l1 = nil
      end
      if name3.nil? and !new_admin_l2.nil then
        name3 = new_admin_l2
        new_admin_l2 = nil
      end
      if name3.nil? and !admin_l3.nil? then
        name3 = new_admin_l3
        new_admin_l3 = nil
      end
      
      logger.debug "Google gave us country: #{new_country}, location: #{name1 || ""}, #{name2 || ""}, #{name3 || ""}"
  
      if self.country_id.nil? || self.country_id == 1
        self.country_id = Country.find_by_cname(new_country).id rescue 1
      end
  
      if self.location_id.nil? || self.location_id == 1 || self.location.name.blank?
        if name1.nil?  || name1 == ""
          self.location_id = 1
        else
          loc = Location.where(:name => name1, :name2 => name2, :name3 => name3, :country_id => self.country_id).first rescue nil
          loc = Location.create(:name => name1, :name2 => name2, :name3 => name3, :country_id => self.country_id) if loc.nil?
          self.location_id = loc.id rescue 1
        end
      end
      self.save
    end

  end

  def average_visibility
    vals = Media.select_values_sanitized('select visibility from dives where spot_id = :id and visibility is not null', :id => self.id)
    return nil if vals.count == 0
    vals.map! do |v|
      case v
      when 'bad' then 2
      when 'average' then 7
      when 'good' then 20
      when 'excellent' then 40
      else nil
      end
    end
    avg = (vals.sum / vals.count).to_f rescue nil

    return nil if avg.nil?
    return 'bad' if avg < 5
    return 'average' if avg < 10
    return 'good' if avg < 25
    return 'excellent'
  end

  def average_current
    vals = Media.select_values_sanitized('select current from dives where spot_id = :id and current is not null', :id => self.id)
    return nil if vals.count == 0
    vals.map! do |v|
      case v
      when 'none' then 0
      when 'light' then 0.5
      when 'medium' then 1.5
      when 'strong' then 2.5
      when 'extreme' then 4
      else nil
      end
    end
    avg = (vals.sum / vals.count).to_f rescue nil

    return nil if avg.nil?
    return 'none' if avg < 0.1
    return 'light' if avg < 1
    return 'medium' if avg < 2
    return 'strong' if avg < 3
    return 'extreme'
  end

  def stats
    if @stats.nil? then
      @stats = Media.select_all_sanitized('select ROUND(avg(temp_bottom),0) avg_bottom_temp, ROUND(avg(temp_surface),0) avg_surface_temp, ROUND(avg(maxdepth),0) avg_depth, ROUND(max(maxdepth),0) max_depth, ROUND(min(maxdepth),0) min_depth from dives where spot_id = :id and temp_bottom is not null', :id => self.id).first
      @stats.keys.each do |k|
        @stats[k] = @stats[k].to_f
      end
    end
    @stats
  end

  def average_temp_bottom
    stats['avg_bottom_temp']
  end

  def average_temp_surface
    stats['avg_surface_temp']
  end

  def average_depth
    stats['avg_depth']
  end

  def max_depth
    stats['max_depth']
  end

  def min_depth
    stats['min_depth']
  end

  def destinationRoutes
    #country = Country.find(self.country_id)
    Rails.logger.debug "OPTI DESTINATIONLINK"

    geonames_country = GeonamesCountries.where("ISO=?",self.country.ccode).first
    return "/area/#{geonames_country.name.to_url}-#{geonames_country.shaken_id}/#{self.name.to_url}-#{self.shaken_id}"
  end

  def mark
    dives = self.dives
    total=0
    count=0
    dives.each do |d|
      if d.review_summary && !d.review_summary.to_f.nan?
        total += d.review_summary
        count += 1
      end
    end
    if count > 0
      total / count
    else nil
    end
  end
  
  def count_review
    count=0
    dives = self.dives
    dives.each do |d|
      count+=1
    end
    count
  end


  def mark_to_moderate
    self.flag_moderate_private_to_public = true
  end


  def check_country
    #closest_spot = Spot.search(:geo => [lat, long],:order => "geodist ASC",:limit=>1).first
    begin
      if self.id == 1
        country_id = 1
        location_id = 1
        return
      end
    rescue

    end

    step=0.01
    closest_spot=nil
    until !closest_spot.nil?
      closest_spot = Spot.where("(lat between ? and ?) and (spots.long between ? and ?) and country_id is not null and country_id != 1",lat-step,lat+step,long-step,long+step).first
      step+=step
    end

    if country.nil? || country.id==1
      self.country_id = closest_spot.country_id
      #we choose 4 as empiric to get 500 km
    elsif country != closest_spot.country && ((lat - closest_spot.lat).abs < 4 || (long - closest_spot.long).abs < 4) 
      mark_to_moderate
    end
  end

  class << self
    def update_compare_table

      while 0 < ActiveRecord::Base.connection.select_value("select count(*) from spots where name like '%  %' or name like ' %' or name like '% '") do
        ActiveRecord::Base.connection.execute "update spots set name = replace(TRIM(name), '  ', ' ')"
      end

      ActiveRecord::Base.connection.reset!
      ActiveRecord::Base.connection.execute "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;"

      ActiveRecord::Base.connection.execute "drop table spot_compare_tmp" rescue nil
      ActiveRecord::Base.connection.execute "create table spot_compare as select 'table is being built'" rescue nil



      ActiveRecord::Base.connection.execute "CREATE TABLE spot_compare_tmp (
            a_id int(11) NOT NULL DEFAULT '0',
            b_id int(11) NOT NULL DEFAULT '0',
            dl_dst int(3) NOT NULL DEFAULT '0',
            1_dst double DEFAULT NULL,
            untrusted_coord int(1) NOT NULL DEFAULT '0',
            included int(0) DEFAULT NULL,
            country_included int(0) DEFAULT NULL,
            same_country int(0) DEFAULT NULL,
            same_region int(0) DEFAULT NULL,
            same_location int(0) DEFAULT NULL
          )"

      ActiveRecord::Base.connection.execute "insert into spot_compare_tmp
        select a.id a_id, b.id b_id,
          case when a.name like 'new spot' or b.name like 'new spot'
                 or a.name like 'unknown spot' or b.name like 'unknown spot'
                 or a.name like 'unknown site' or b.name like 'unknown site'
                 or a.name like 'unknown site, unknown %' or b.name like 'unknown site, unknown %'
               then 999
               else damlevlim256(a.name, b.name, 3) end dl_dst,
          least( 2*ABS(a.lat-b.lat)+ABS(a.long-b.long)*cos(LEAST(ABS(a.lat), ABS(b.lat))*PI()/180 ),
                 2*ABS(a.lat-b.lat)+ABS(a.long-b.long-360)*cos(LEAST(ABS(a.lat), ABS(b.lat))*PI()/180),
                 2*ABS(a.lat-b.lat)+ABS(a.long-b.long+360)*cos(LEAST(ABS(a.lat), ABS(b.lat))*PI()/180)) 1_dst,
          a.lat = 0 or b.lat = 0 or a.long=0 or b.long=0 untrusted_coord,
          case when a.name = b.name and length(a.name)>4 then 0
               when a.name like CONCAT(b.name, '%') and length(b.name)>4 then 1
               when b.name like CONCAT(a.name, '%') and length(a.name)>4 then 2
               else null end  included,
          case when a.name like CONCAT('%', cb.cname, '%') then 1
               when b.name like CONCAT('%', ca.cname, '%') then 2
               else null end  country_included,
          case when a.country_id = 1 or b.country_id = 1 then null
               when a.country_id = b.country_id then 1
               else 0 end same_country,
          case when a.region_id = 1 or b.region_id = 1 then null
               when a.region_id = b.region_id then 1
               else 0 end same_region,
          case when a.location_id = 1 or b.location_id = 1 then null
             when a.location_id = b.location_id then 1
             else 0 end same_location
        from spots a
          left join countries ca on a.country_id = ca.id and ca.id <> 1
          join spots b
          left join countries cb on b.country_id = cb.id and cb.id <> 1
        where a.id < b.id and a.id <> 1
          and length(a.name) > 0 and length(b.name) > 0
          and a.redirect_id is null and b.redirect_id is null
          and NOT(a.flag_moderate_private_to_public IS NOT NULL AND a.flag_moderate_private_to_public = 0 AND a.private_user_id IS NULL)
          and NOT(b.flag_moderate_private_to_public IS NOT NULL AND b.flag_moderate_private_to_public = 0 AND b.private_user_id IS NULL)
        having (same_country = 1 or same_country is null)
           and (dl_dst<=2 or included is not null)
           and (1_dst < 4 or untrusted_coord)"

      ActiveRecord::Base.connection.execute "alter table spot_compare_tmp add column match_class VARCHAR(255)"
      ActiveRecord::Base.connection.execute "alter table spot_compare_tmp add column cluster_id int"

      ActiveRecord::Base.connection.execute "delete from spot_compare_tmp where (select count(*) from spot_moderations m where spot_compare_tmp.a_id = m.a_id and spot_compare_tmp.b_id = m.b_id )"

      ActiveRecord::Base.connection.execute "update spot_compare_tmp set cluster_id = a_id"

      ActiveRecord::Base.connection.execute "update spot_compare_tmp set match_class =
        case
        when same_country and dl_dst=0 and untrusted_coord = 0 and 1_dst < 1 then 'perfect_match 1'
        when same_country is null and same_region=1 and dl_dst=0 and untrusted_coord = 0 and 1_dst < 1 then 'perfect_match 2'
        when dl_dst=0 and untrusted_coord = 0 and 1_dst < 1 then 'good_match 1'
        when untrusted_coord = 0 and dl_dst < 3 and 1_dst < 0.1 then 'good_match 2'
        when untrusted_coord = 1 and dl_dst = 0 and 1_dst < 1 then 'to_check 1'
        when untrusted_coord = 1 and dl_dst = 0 and same_country = 1 then 'potential_match 1'
        when dl_dst=1 and untrusted_coord = 0 and 1_dst < 1 then 'potential_match 2'
        when included is not null and same_country and untrusted_coord = 0 and 1_dst < 1 then 'to_check 2'
        when same_country and dl_dst=0 and untrusted_coord = 0 then 'far_match 1'
        when same_country is null and same_region=1 and dl_dst=0 and untrusted_coord = 0 and 1_dst < 1 then 'far_match 2'
        when untrusted_coord = 0 and dl_dst < 3 and 1_dst < 1 then 'potential_match 3'
        when untrusted_coord = 0 and 1_dst < 0.1 and included is not null then 'potential_match 4'
        when untrusted_coord = 0 and 1_dst < 1 and included is not null then 'far_match 3'
        when dl_dst <= 1 and 1_dst >= 1 then 'to_check 2'
        when dl_dst > 1 and 1_dst >= 1 then 'untrusted'
        when untrusted_coord = 1 then 'untrusted'
        else null
        end"

      ActiveRecord::Base.connection.execute "create index spot_compare_idx1 on spot_compare_tmp (a_id, match_class, b_id)"
      ActiveRecord::Base.connection.execute "create index spot_compare_idx2 on spot_compare_tmp (b_id, match_class, a_id)"

      #Joining the clusters
      updated_rows = 1
      while updated_rows > 0 do
        updated_rows = ActiveRecord::Base.connection.update_sql "update spot_compare_tmp, (select c.* from spot_compare_tmp c
          where c.match_class in ('perfect_match 1', 'perfect_match 2', 'good_match 1', 'good_match 2', 'good_match 3')
          group by c.b_id
          having c.a_id = min(c.a_id)) prev_node
          set spot_compare_tmp.cluster_id = prev_node.cluster_id
          where spot_compare_tmp.a_id = prev_node.b_id
            and spot_compare_tmp.cluster_id <> prev_node.cluster_id"
        Rails.logger.debug "Updated : #{updated_rows}"
      end

      ActiveRecord::Base.connection.execute "create index spot_compare_idx3 on spot_compare_tmp (cluster_id, match_class)"

      #Activating the new table
      ActiveRecord::Base.connection.execute "rename table spot_compare to spot_compare_old, spot_compare_tmp to spot_compare"
      ActiveRecord::Base.connection.execute "drop table spot_compare_old"

      #reset spots marked as discarded during last moderation process
      ActiveRecord::Base.connection.execute "delete from spot_moderations where b_id is null"

      ActiveRecord::Base.connection.reset!

    end
    handle_asynchronously :update_compare_table, :queue => :admin_tasks
  end

end
