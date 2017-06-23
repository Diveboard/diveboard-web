class Advertisement < ActiveRecord::Base
  extend FormatApi

  belongs_to :user
  belongs_to :picture


  define_format_api :public => [:id, :lat, :lng, :title, :text, :redirect_url, :thumbnail],
    :private => [ :user_id, :created_at, :ended_at, :picture_id, :external_url, :deleted, :print_count, :click_count,
      shop_permalink: lambda {|ad| ad.user.shop_proxy.permalink rescue nil}
    ],
    :search_light => [:id, :lat, :lng, :title, :text, :redirect_url, :thumbnail]

  define_api_includes :private => [:public], :search_light => [], :search_full => [:search_light, :public]

  define_api_updatable_attributes %w( text title external_url picture_id ended_at user_id deleted moderate_id)

  before_save :enforce_ad_restriction!
  before_save :ensure_ended_if_deleted!
  after_save :update_explore_assets

  LOCAL_RADIUS = 4

  def is_private_for?(options = {})
    begin
      return true if self.user_id.nil? #well.... not really.... TODO!!!
      return true if options[:private]
      return true if options[:caller].id == self.user_id rescue false
      return true if self.user.is_private_for?(options) rescue false
      return false
    rescue
      return false
    end
  end

  def local_divers
    User.where("shop_proxy_id IS NULL AND city is not NULL")
      .where(position_condition(:users),
      {:lat => self.lat, :lng => self.lng, :radius => LOCAL_RADIUS})
      .order("(lat-#{self.lat})*(lat-#{self.lat}) + (lng-#{self.lng})*(lng-#{self.lng})")
  end

  def frequent_divers
    return []
  end

  def thumbnail
    picture.thumbnail rescue nil
  end

  def redirect_url
    external_url || self.user.fullpermalink(:locale)
  end

  def delete
    self.deleted = true
    self.ended_at = Time.now if self.ended_at.nil?
    self.save!
  end

  def destroy
    self.deleted = true
    self.ended_at = Time.now if self.ended_at.nil?
    self.save!
  end

  def ended_at= val
    #ended_at should not be written with anything
    write_attribute(:ended_at, Time.now)
  end

  def deleted= val
    write_attribute(:deleted, true)
  end

  def text= val
    Rails.logger.debug "Text is set to #{val}"
    write_attribute(:text, val)
  end

  def lat
    lat = read_attribute(:lat)
    lng = read_attribute(:lng)
    return user.shop_proxy.lat if lat.nil? || lng.nil?
    return lat
  end

  def lng
    lat = read_attribute(:lat)
    lng = read_attribute(:lng)
    return user.shop_proxy.lng if lat.nil? || lng.nil?
    return lng
  end

  def print_count
    ad_ids = moderation_list
    Media.select_all_sanitized("select sum(nb) as cnt from stats_sums where col1 in :ids and aggreg='ad' and col2='print'", :ids => ad_ids).first['cnt'].to_i || 0 rescue 0
  end

  def click_count
    ad_ids = moderation_list
    Media.select_all_sanitized("select sum(nb) as cnt from stats_sums where col1 in :ids and aggreg='ad' and col2='click'", :ids => ad_ids).first['cnt'].to_i || 0 rescue 0
  end

  def moderate_id=val
    previous = Advertisement.find(val) rescue nil
    return if previous.nil?
    return if previous.user_id != self.user_id
  end

private

  def moderation_list
    ad_ids = []
    cursor = self
    while !cursor.nil? do
      ad_ids.push cursor.id
      if cursor.moderate_id && !ad_ids.include?(cursor.moderate_id) then
        cursor = Advertisement.find(cursor.moderate_id) rescue nil
      else
        cursor = nil
      end
    end
    return ad_ids
  end

  def position_condition(table='users')
    lat_condition = "lat BETWEEN :lat - :radius and :lat + :radius "
    if self.lng + LOCAL_RADIUS > 180 then
      return "#{lat_condition} AND (#{table}.lng BETWEEN :lng - :radius and 180 OR #{table}.lng BETWEEN -180 and :lng + :radius - 360)"
    elsif self.lng - LOCAL_RADIUS < 180 then
      return "#{lat_condition} AND (#{table}.lng BETWEEN -180 and :lng + :radius OR #{table}.lng BETWEEN :lng - :radius + 360 and 180)"
    else
      return "#{lat_condition} AND #{table}.lng BETWEEN :lng - :radius and :lng + :radius"
    end
  end

  def ensure_ended_if_deleted!
    self.ended_at = Time.now if self.deleted && self.ended_at.nil?
  end

  def enforce_ad_restriction!
    self.lat = nil
    self.lng = nil
  end

  def update_explore_assets
    set = self.changed_attributes
    previous_lat = set['lat'] || self.lat
    previous_lng = set['lng'] || self.lng
    ExploreHelper::Slicer.del_element 'ads', previous_lat, previous_lng, self.id
    ExploreHelper::Slicer.add_element 'ads', self.to_api(:search_light) if self.ended_at.nil?
  end
  handle_asynchronously :update_explore_assets

end
