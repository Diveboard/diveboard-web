class Location < ActiveRecord::Base
  extend FormatApi


  belongs_to :country
  has_and_belongs_to_many :regions, :join_table => "locations_regions", :uniq => true
  has_many :spots
  has_many :dives, :through => :spots
  alias :dive_ids :dife_ids
  #has_many :users, :through => :dives # will work with rails 3.1...

  #before_create :reload_old_if_exists

  cattr_accessor :userid  ## this defines the current user context


  define_format_api :public => [ :blob, :shaken_id, :name, :name2, :name3, :permalink, :fullpermalink, :is_public],
                    :private => [ ],
                    :search_light => [ {
                      :thumbnail => Proc.new {|p| p.picture.thumbnail rescue nil },
                      :large => Proc.new {|p| p.picture.large rescue nil},
                      :dive_ids => Proc.new do |s| begin (s.dives.reject do |d| d.privacy==1 end).map &:id rescue [] end end
                    }],
                    :search_full => [ :wiki_html, {
                      :has_wiki_content => Proc.new {|p| p.wiki.nil?}
                    }],
                    :search_full_server => [ ],
                    :search_full_server_l1 => [ ],
                    :search_full_server_l2 => [ ]

  define_api_includes :* => [:public], :search_full => [:search_light], :search_full_server => [:search_full], :search_full_server_l1 => [:search_full], :search_full_server_l2 => [:search_full]

  define_api_updatable_attributes %w( name country_id)
  define_api_updatable_attributes_rec({})


  def is_private_for?(options={})
    ##can create
    return true if options[:action]==:create
    #cannot update
    return false
  end



  ##Only create a new location when it makes sense
  def create
    begin
      if self.id.nil? then
        Rails.logger.debug "trying to dedup Location on name #{self.name}"
        self.name = "" if self.name.nil? # we don't want nil ....
        old = Location.where(:name => self.name, :name2=> self.name2, :name3=> self.name3, :country_id => self.country_id).first
        ##TODO moderate if more than one answer...
        ##TODO Copy other parameters that may have been set...
        if !old.blank? then
          Rails.logger.debug "Loading #{old.id}:"
          self.id = old.id
          self.reload
          @new_record = false ## I'm lying
          return self.id
        end
      end
    rescue
      Rails.logger.debug "Deduplication of Location failed with "+$!.message
    end

    super()
  end

  def is_public
    true
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

  def pictures
    self.dives.map(&:pictures).flatten
  end

  def best_pic_ids=l
    write_attribute(:best_pic_ids, JSON.unparse(l))
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

  def merge_into location_id
    ##will merge current location into location_id and update all spots pointing to the current location
    if self.id == location_id
      #I'm not merging myself
      return
    end
    destination = Location.find(location_id)
    errors =[]
    self.spots.each do |s|
      begin
        if s.country_id != destination.country_id
          raise DBArgumentError.new "can't merge locations since there is a spot has different country", location_from: self.id, location_to: location_id, spot_id: s.id
        end
        mybackup = s.to_api :moderation, :private => true
        s.location_id = location_id
        s.save
        ModHistory.create(:obj_id => s.id, :table => s.class.to_s, :operation => MOD_UPDATE, :before => mybackup, :after => s.to_api(:moderation, :private => true))
      rescue
        Rails.logger.error $!.message
        errors.push s.id
      end
    end

    ## updated the permalinks
    redirect_permalinks location_id

    ## we DO NOT DELETE the location : it will be purged later after checking no spot uses it

    if !errors.blank?
      raise DBArgumentError.new "Merge of locations failed on spots", location_from: self.id, location_to: location_id, errors: errors
    end
  end

  def permalink
    "#{self.country.permalink}/#{blob}"
  end
  def blob
    if name.blank?
      "unnamed-location-#{shaken_id}"
    else
      "#{name.to_url}-#{shaken_id}"
    end
  end
  def fullpermalink *options
    HtmlHelper.find_root_for(*options).chop + permalink
  end
  def shaken_id
    "L#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "L"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end

  def update_bounds
    if self.country_id.blank? || self.country_id == 1
      self.nesw_bounds = nil
      self.save!
      return
    end
    name = URI.escape "#{self.country.cname}, #{self.name}"
    data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{name}&sensor=false")
      jsondata = JSON.parse(data.read)
      if jsondata["status"] == "OVER_QUERY_LIMIT"
        return
      else
        begin
          self.nesw_bounds = jsondata["results"][0]["geometry"].to_json
        rescue
          self.nesw_bounds = nil
        end
        self.save
      end
  end

  def bounds
  end
end
