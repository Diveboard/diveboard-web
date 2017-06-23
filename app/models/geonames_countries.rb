class GeonamesCountries < ActiveRecord::Base
	attr_accessor :list
	def bestGeonamesCore
		#SELECT * from `geonames_cores` where `country_code` = "VA" and `feature_code`= "ADM1";
		self.list=GeonamesCore.where("country_code = ? AND feature_code=?",self.ISO,"ADM1")
	end

	def localReviews
		reviews = Review.joins("LEFT join shops on shops.id=shop_id").where("shops.score is not null and shops.country_code=?",self.ISO)
	end

	def localMark

=begin
		if self.list.nil?
			self.bestGeonamesCore
		end
		self.list.each do |g|
			tmp=g.localAvg
			if tmp != 0
				mark += tmp
				count +=1
			end
		end
=end
		return ActiveRecord::Base.connection.select_value("select avg( case dr.name when 'overall' then 1 when 'marine' then 0.9 when 'wreck' then 0.9 when 'bigfish' then 0.8 when 'difficulty' then 0.8 end * mark) from dive_reviews dr left join dives d on dr.dive_id=d.id left join spots s on d.spot_id=s.id left join countries c on c.id = s.country_id where c.ccode like '#{self.ISO}';")
		#return DiveReview.joins("left join dives d on dr.dive_id=d.id").joins("left join spots s on d.spot_id=s.id").joins("left join countries c on c.id = s.country_id").where("c.ccode like '#{self.ISO}'").select("case dr.name when 'overall' then 1 when 'marine' then 0.9 when 'wreck' then 0.9 when 'bigfish' then 0.8 when 'difficulty' then 0.8 end * mark")
 
	end

	def localSpots id, minLat, minLng, maxLat, maxLng
		if minLng > maxLng
			spots = Spot.where("score is not null and country_id=? and region_id is not null and (spots.lat BETWEEN ? AND ?) AND not (spots.long BETWEEN ? AND ?)",id,minLat, maxLat,minLng, maxLng).order("score desc")
		else
			spots = Spot.where("score is not null and country_id=? and region_id is not null and (spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)",id,minLat, maxLat,minLng, maxLng).order("score desc")
		end
	end

	def localDives minLat, minLng, maxLat, maxLng
		if minLng > maxLng
			dives = Dive.joins("LEFT join spots ON spots.id = spot_id").where("(spots.lat BETWEEN ? AND ?) AND not (spots.long BETWEEN ? AND ?)",minLat, maxLat,minLng, maxLng)
		else
			dives = Dive.joins("LEFT join spots ON spots.id = spot_id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)",minLat, maxLat,minLng, maxLng)
		end
	end

	def localDivesReviews minLat, minLng, maxLat, maxLng
		reviews = DiveReview.joins("LEFT join dives on dives.id=dive_id").joins("LEFT join spots ON spots.id = spot_id").where("(spots.lat BETWEEN ? AND ?) AND not (spots.long BETWEEN ? AND ?)",minLat, maxLat,minLng, maxLng).order("dive_id")
	end
	def localAvgDives dives
		total=0
		count=0
		dives.each do |d|
			if d.review_summary!=nil
				total+=d.review_summary
				count+=1
			end
		end
		total/count
	end
	def localShops	
		shops = Shop.where("score is not null and country_code=?",self.ISO).order("score desc")
	end

	def headerPicture id
		headerPicture = Picture.joins("LEFT JOIN picture_album_pictures ON pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON picture_album_pictures.picture_album_id = dives.album_id LEFT JOIN spots ON dives.spot_id = spots.id").where("spots.country_id = ? AND pictures.user_id IS NOT NULL AND great_pic = true",id).limit(1).first
	end


	def shaken_id
	    "G#{Mp.shake(self.id)}"
	  end

	def self.fromshake code
		self.find(idfromshake code)
	end

	def self.idfromshake code
		if code[0] == "G"
	    	i =  Mp.deshake(code[1..-1])
	    else
	    	i = Integer(code.to_s, 10)
	    end
	    if i.nil?
	    	raise DBArgumentError.new "Invalid ID"
	    else
	    	target = GeonamesCountries.find(i)
	    end
	  end
end
