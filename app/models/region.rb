class Region < ActiveRecord::Base
  extend FormatApi


  has_and_belongs_to_many :countries, :join_table => "countries_regions", :uniq=>true
  has_and_belongs_to_many :locations, :join_table => "locations_regions", :uniq=>true
  has_many :spots
  has_many :dives, :through => :spots
  alias :dive_ids :dife_ids
  #has_many :users, :through => :dives  # will work with rails 3.1

  cattr_accessor :userid  ## this defines the current user context


  define_format_api :public => [ :blob, :shaken_id, :name, :permalink, :fullpermalink, :is_public],
                    :private => [ ],
                    :search_light => [ {
                      :thumbnail => Proc.new {|p| p.best_pic.thumbnail rescue nil },
                      :large => Proc.new {|p| p.best_pic.large rescue nil},
                      :dive_ids => Proc.new do |s| begin (s.dives.reject do |d| d.privacy==1 end).map &:id rescue [] end end
                    }],
                    :search_full => [:wiki_html, {
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

##Only create a new opbject when it's really new when it makes sense
  def create
    begin
      if self.id.nil? then
        Rails.logger.debug "trying to dedup Region creation on name #{self.name}"
        old = Region.where(:name => self.name).first
        ##TODO moderate if more than one answer...
        if !old.nil? then
          Rails.logger.debug "Loading #{old.id}:"
          self.id = old.id
          self.reload
          @new_record = false ## I'm lying
          return self.id
        end
      end
    rescue
      Rails.logger.debug "Deduplication of Region failed with "+$!.message
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

  def permalink
    "/explore/spots/zone/#{blob}"
  end
  def blob
    if name.blank?
      "unnamed-body-of-water-#{shaken_id}"
    else
      "#{name.to_url}-#{shaken_id}"
    end
  end
  def fullpermalink option=nil
    HtmlHelper.find_root_for(option).chop + permalink
  end
  def shaken_id
    "R#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "R"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end

  def localReviews
    #self.update_bounds
    return [] if nesw_bounds.nil?

    minLat = nesw_bounds["southwest"]["lat"]
    minLng = nesw_bounds["southwest"]["lng"]
    maxLat = nesw_bounds["northeast"]["lat"]
    maxLng = nesw_bounds["northeast"]["lng"]
    reviews = Review.joins("LEFT join shops on shops.id=shop_id").where("(shops.lat between ? and ?) and (shops.lng between ? and ? )",minLat,maxLat,minLng,maxLng)
  end

  def localShops
    #self.update_bounds
    return [] if nesw_bounds.nil?

    minLat = nesw_bounds["southwest"]["lat"]
    minLng = nesw_bounds["southwest"]["lng"]
    maxLat = nesw_bounds["northeast"]["lat"]
    maxLng = nesw_bounds["northeast"]["lng"]
    shops = Shop.where("(shops.lat between ? and ?) and (shops.lng between ? and ? )",minLat,maxLat,minLng,maxLng)
  end

  def localSpots country_id
    #self.update_bounds
    return [] if nesw_bounds.nil?

    minLat = nesw_bounds["southwest"]["lat"]
    minLng = nesw_bounds["southwest"]["lng"]
    maxLat = nesw_bounds["northeast"]["lat"]
    maxLng = nesw_bounds["northeast"]["lng"]
    return Spot.where("country_id = ? and (spots.lat between ? and ?) and (spots.long between ? and ? )",country_id,minLat,maxLat,minLng,maxLng)
  end

  def localDives country_id
    dives= self.dives.where("spots.country_id=?",country_id).order("score desc")
  end

  def localDivesReviews dives
    divesReviews = []
    dives.each do |d|
      divesReviews.push(*d.dive_reviews)
    end
  end

  def mark spots
    total=0
    count=0
    spots.each do |s|
      if s.mark != nil
        total+=s.mark
        count+=1
      end
    end  
    if count>0
      total/count
    end
  end

  def nesw_bounds
    JSON.parse(read_attribute :nesw_bounds) rescue nil
  end

  def update_bounds
    name = URI.escape "#{self.name}"
    data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{name}&sensor=false")
      jsondata = JSON.parse(data.read)
      if jsondata["status"] == "OVER_QUERY_LIMIT"
        return false
      else
        begin
          self.nesw_bounds = JSON.unparse(jsondata["results"][0]["geometry"]["bounds"])
        rescue
          self.nesw_bounds = nil
        end
        self.save
      end
  end
end
