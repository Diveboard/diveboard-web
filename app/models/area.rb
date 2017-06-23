# -*- coding: utf-8 -*-
class Area < ActiveRecord::Base

	attr_accessible *column_names
	attr_accessible :distance
	belongs_to :geonames_core
	belongs_to :favorite_picture, :class_name => :Picture, :foreign_key => 'favorite_picture_id'
	has_many :area_categories
  
	before_save :generate_fullpermalink

	def generate_fullpermalink
		if !self.geonames_core.nil?
			self.url_name = self.geonames_core.asciiname.to_url
		end
	end

	def spots
		init_up_coord
		Spot.where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng)
	end
 
	def pictures limit = 10
		init_up_coord
		Picture.joins("LEFT JOIN picture_album_pictures ON pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON picture_album_pictures.picture_album_id = dives.album_id LEFT JOIN spots ON dives.spot_id = spots.id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) AND pictures.user_id IS NOT NULL", @upMinLat, @upMaxLat, @upMinLng, @upMaxLng).limit(limit)
	end

	def pictures_with_ratio min, max, limit = 10
		self.pictures(limit).find_pic(min, max)
	end

	def best_pictures limit = 100
		self.pictures(limit).where("great_pic = true")
	end

	def best_pictures_with_ratio min, max, limit = 10
		self.best_pictures(limit).find_best_pic(min, max)
	end

	def header_picture
		if best_pictures_with_ratio(1.8, 2.4).size != 0
			return best_pictures_with_ratio(1.8, 2.4).sample
		elsif best_pictures.size != 0
			return best_pictures.sample
		elsif pictures_with_ratio(1.8, 2.4).size != 0
			return pictures_with_ratio(1.8, 2.4).sample
		else
			return pictures.sample
		end
	end

	def reviews
		if @reviews.nil?
			@reviews = DiveReview.joins("LEFT JOIN dives ON dive_reviews.dive_id = dives.id LEFT JOIN spots ON dives.spot_id = spots.id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng)
		end
		return @reviews
	end

	def count_reviews
		reviews.select("dive_id").uniq.size
	end

	def dives
		if @dives.nil?
			@dives = Dive.joins("LEFT JOIN spots ON dives.spot_id = spots.id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) AND privacy = 0", minLat, maxLat, minLng, maxLng)
		end
		return @dives
	end

	def dives_order_by_overall_and_notes limit, offset=0
		max = dives.size
		result = Array.new
		hash_array = Hash.new
		size = offset + limit
		tmp_offset = 0
		while (result.size < size)
			if tmp_offset > max
				break
			end
			dives = Dive.unscoped.joins("LEFT JOIN spots ON dives.spot_id = spots.id").joins("LEFT JOIN dive_reviews ON dive_reviews.dive_id = dives.id AND dive_reviews.name = \"overall\"").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) AND privacy = 0", minLat, maxLat, minLng, maxLng).select("dives.*, LENGTH(dives.notes) AS len").order("dive_reviews.mark DESC, len DESC").limit(limit).offset(tmp_offset)
			dives = dives.to_a
			tmp_offset += limit
			dives.each do |d|
				if (!d.user.nil? && d.user.share_details_notes == false) || d.dive_reviews.size == 0
					dives.delete d
				else
					if !hash_array.has_key?(d.user_id.to_s)
  			  	hash_array[d.user_id.to_s] = true;
  			  	result.push(d)
  				end
				end
			end
		end
		return result.from(offset).to(limit - 1)
	end

	def shops limit, offset=nil
		if !offset.nil?
			result = Shop.includes(:user_proxy).where('users.id is not null').where("(shops.lat BETWEEN ? AND ?) AND (shops.lng BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng).order("shops.score DESC").offset(offset).limit(limit)
		else
			result = Shop.includes(:user_proxy).where('users.id is not null').where("(shops.lat BETWEEN ? AND ?) AND (shops.lng BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng).order("shops.score DESC").limit(limit)
		end
		return result
	end

	def first_n_reviews nb_reviews
		dives_order_by_overall_and_notes.to(nb_reviews)
	end

	def shopsReviews
		if @shopsreviews.nil?
			@shopsreviews = Review.joins("LEFT JOIN shops on shops.id = reviews.shop_id").where("(lat BETWEEN ? AND ?) AND (lng BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng)
		end
		return @shopsreviews
	end

	def mark
		total_percent_add = 0
		total_percent = 0

		self.reviews.each do |r|
			total_percent_add += r.mark * 20
			total_percent += 1
		end

		self.shopsReviews.each do |s|
			if s.recommend == 1
				total_percent_add += 70
			else
				total_percent_add += 10
			end
			if !s.mark_orga.nil? && s.mark_orga != 0
				total_percent_add += s.mark_orga * 20
				total_percent += 1
			end
			if !s.mark_friend.nil? && s.mark_friend != 0
				total_percent_add += s.mark_friend * 20
				total_percent += 1
			end
			if !s.mark_secu.nil? && s.mark_secu != 0
				total_percent_add += s.mark_secu * 20
				total_percent += 1
			end
			if !s.mark_boat.nil? && s.mark_boat != 0
				total_percent_add += s.mark_boat * 20
				total_percent += 1
			end
			if !s.mark_rent.nil? && s.mark_rent != 0
				total_percent_add += s.mark_rent * 20
				total_percent += 1
			end
			total_percent += 1
		end
		if total_percent == 0
			return 0
		end
		return total_percent_add / total_percent
	end

	def near_areas limit, offset=0
		lat = (((maxLat - minLat) / 2.0) + minLat)
		lng = (((maxLng - minLng) / 2.0) + minLng)
		areas = Area.select("areas.*, 6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(" + lat.to_s + " - ABS((((areas.maxLat - areas.minLat) / 2) + areas.minLat))) / 2), 2) + COS(RADIANS(" + lat.to_s + ")) * COS(RADIANS(ABS((((areas.maxLat - areas.minLat) / 2) + areas.minLat)))) * POWER(SIN(RADIANS(" + lng.to_s + " - (((areas.maxLng - areas.minLng) / 2) + areas.minLng))), 2))) AS distance").order("distance").where("id != ? AND active = ?", id, true).limit(limit).offset(offset)
		return areas
	end

	def self.near_areas lat, lng, limit, offset=0
		areas = Area.select("areas.*, 6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(" + lat.to_s + " - ABS((((areas.maxLat - areas.minLat) / 2) + areas.minLat))) / 2), 2) + COS(RADIANS(" + lat.to_s + ")) * COS(RADIANS(ABS((((areas.maxLat - areas.minLat) / 2) + areas.minLat)))) * POWER(SIN(RADIANS(" + lng.to_s + " - (((areas.maxLng - areas.minLng) / 2) + areas.minLng))), 2))) AS distance").order("distance").where("active = ?", true).limit(limit).offset(offset)
		return areas
	end

	#TODO Optimise with sql call
	def getDiveRewiewMarkByTag tag
		total_percent_add = 0
		total_percent = 0
		self.reviews.where(name: tag).each do |r|
			total_percent_add += r.mark
			total_percent += 1
		end
		if total_percent == 0
			return 0
		end
		return total_percent_add / total_percent
	end

	def getDifficultyMark
		getDiveRewiewMarkByTag "difficulty"
	end

	def getMarineLifeMark
		getDiveRewiewMarkByTag "marine"
	end

	def getOverallMark
		getDiveRewiewMarkByTag "overall"
	end

	def getShopMark
		total_percent_add = 0
		total_percent = 0
		self.shopsReviews.each do |s|

			if !s.mark_orga.nil? && s.mark_orga != 0
				total_percent_add += s.mark_orga
				total_percent += 1
			end
			if !s.mark_friend.nil? && s.mark_friend != 0
				total_percent_add += s.mark_friend
				total_percent += 1
			end
			if !s.mark_secu.nil? && s.mark_secu != 0
				total_percent_add += s.mark_secu
				total_percent += 1
			end
			if !s.mark_boat.nil? && s.mark_boat != 0
				total_percent_add += s.mark_boat
				total_percent += 1
			end
			if !s.mark_rent.nil? && s.mark_rent != 0
				total_percent_add += s.mark_rent
				total_percent += 1
			end
		end
		return total_percent_add /total_percent
	end

	def picture
    return best_pictures.sample
  end

  def fullpermalink *args
    return HtmlHelper.find_root_for(*args).chop + permalink
  end

  def permalink *args
    return "/area/" + url_country + "/" + url_name
  end

  def url_country
  	return geonames_core.country.cname.to_url
  end

  def average_temp_surface
  	result = dives.average("CASE WHEN temp_surface_unit = 'F' then (temp_surface_value - 32) * 5 / 9 WHEN temp_surface_unit = 'C' then temp_surface_value else NULL END")
  	if result.nil?
  		return nil
  	end
  	if result.round == 0
  		return nil
  	else
  		return result
  	end
  end

  def average_temp_bottom
  	result = dives.average("CASE WHEN temp_bottom_unit = 'F' then (temp_bottom_value - 32) * 5 / 9 WHEN temp_bottom_unit = 'C' then temp_bottom_value else NULL END")
  	if result.nil?
  		return nil
  	end
   	if result.round == 0
  		return nil
  	else
  		return result
  	end
  end

  def average_depth
  	result = dives.average("CASE WHEN maxdepth_unit = 'ft' and maxdepth_value > 9 then maxdepth_value / 3.2808 WHEN maxdepth_unit = 'm' and maxdepth_value > 3 then maxdepth_value else NULL END")
  	if result.nil?
  		return nil
  	end
  	if result.round == 0
  		return nil
  	else
  		return result
  	end
  end

  private
    def init_up_coord
	  	@adding_size = 1.0
	  	@upMinLat = minLat - @adding_size
	  	@upMinLng = minLng - @adding_size
	  	@upMaxLat = maxLat + @adding_size
	  	@upMaxLng = maxLng + @adding_size
	  end
end
