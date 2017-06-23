class Country < ActiveRecord::Base
  extend FormatApi


  cattr_accessor :userid  ## this defines the current user context

  has_many :spots
  has_and_belongs_to_many :regions, :join_table => "countries_regions", :uniq =>true
  has_many :locations
  has_many :dives, :class_name => 'Dive', :through => :spots
  has_many :fb_likes, :class_name => "FbLike", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id
  alias :dive_ids :dife_ids
  #has_many :users, :through => :dives #will work with rails 3.1.....


  define_format_api :public => [:blob, :shaken_id, :cname, :ccode, :flag_big, :permalink, :fullpermalink, :flag_small, :id, :name],
                    :private => [],
                    :search_light => [ :id, :name, :bounds, {
                      :thumbnail => Proc.new {|p| p.picture.thumbnail rescue nil },
                      :large => Proc.new {|p| p.picture.large rescue nil},
                      :dive_ids => Proc.new do |s| begin (s.dives.reject do |d| d.privacy==1 end).map &:id rescue [] end end
                    }],
                    :search_full => [ :wiki_html, {
                      :has_wiki_content => Proc.new {|p| p.wiki.nil?},
                      :best_pics => Proc.new {|p| Picture.find(p.best_pic_ids[0..20]).to_api :public}
                    }, :spot_ids],
                    :search_full_server => [
                        dives: lambda {|c| Dive.find( Media.select_values_sanitized("select dives.id from spots, dives where dives.privacy <> 1 and dives.spot_id = spots.id and spots.country_id = :country_id  order by dives.score DESC limit 20", country_id: c.id)).map do |d| d.to_api :search_full_server_l1 end}
                      ],
                    :search_full_server_l1 => [ ],
                    :search_full_server_l2 => [ ],
                    :wiki => [
                      :wiki_html,
                      :best_pics => Proc.new {|p| p.best_pics.to_api :public}
                    ]

  define_api_includes :private => [:public], :search_light => [:public], :search_full => [:search_light, :public]

  define_api_includes :private => [:public], :search_light => [:public], :search_full => [:search_light, :public], :search_full_server => [:search_full], :search_full_server_l1 => [:search_full], :search_full_server_l2 => [:search_full]


  def self.blank
    return Country.where(:ccode => 'BLANK').first
  end

  def cname
    return read_attribute(:cname) if I18n.locale == :en
    alt = Media.select_value_sanitized "select a.name from geonames_countries c, geonames_alternate_names a where c.ISO=:iso and a.geoname_id = c.geonames_id and a.language=:lang order by preferred DESC", iso: self.ccode.upcase, lang: I18n.locale
    alt || read_attribute(:cname)
  end

  def name
    self.cname
  end

  def most_common_species
    if !self.nesw_bounds.nil? && !self.nesw_bounds.empty?
      bounds = nesw_bounds.split(",")
      #return Eolsname.most_common_in_area(bounds[0].to_i,bounds[1].to_i,bounds[2].to_i,bounds[3].to_i)
      return Eolsname.most_common(self.spots.first.lat.to_i, self.spots.first.long.to_i)
    else
      return []
    end
  end

  def wiki
     Wiki.get_wiki(self.class.to_s, self.id, userid)
  end

  def wiki_html
    begin
      HtmlHelper.sanitize self.wiki.data.html_safe
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

  def path_to_flag
    flag_small
  end

  def flag_small
    ROOT_URL+"img/flags/"+ccode.downcase+".gif"
  end

  def flag_big
    ROOT_URL+"img/flags/hd/"+ccode.downcase+".png"
  end

  def permalink
    "/explore/spots/#{blob}"
  end
  def blob
    if name.blank?
      "country"
    else
      "#{name.to_url}"
    end
  end
  def fullpermalink *options
    HtmlHelper.find_root_for(*options).chop + permalink
  end
  def shaken_id
    "C#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "C"
       return Mp.deshake(code[1..-1])
    else
       return Integer(code.to_s, 10)
    end
  end
  def bounds
    JSON.parse(nesw_bounds) unless nesw_bounds.nil?
  end

  def update_fb_like
    FbLike.get self
  end
  handle_asynchronously :update_fb_like


end
