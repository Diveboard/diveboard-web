class GeonamesCore < ActiveRecord::Base
  #has_many :childrens, :class_name => "GeonamesCore", :foreign_key => "parent_id"
  #belongs_to :parent, :class_name => "GeonamesCore", :foreign_key => "parent_id"
  #has_one :type, :class_name => "GeonamesFeaturecodes", :foreign_key => "feature_code", :association_foreign_key => "feature_code"

  belongs_to :country, :foreign_key => :country_code, :primary_key => :ccode
  has_one :area


  def localShops
  	#@shops = Shop.search(self.name)
    @shops = []
    step = 0.1
    minLat = self.latitude
    minLng = self.longitude
    maxLat = self.latitude
    maxLng = self.longitude
    until @shops.length >= 6
      minLat -= step
      minLng -= step
      maxLat += step
      maxLng += step
      @shops = Shop.includes(:user_proxy).where('users.id is not null').where("(shops.lat BETWEEN ? AND ?) AND (shops.lng BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng).order("shops.score DESC").limit(6)
    end
    @shops
  end

  def localPictures
    @pictures = []
    step = 0.1
    minLat = self.latitude
    minLng = self.longitude
    maxLat = self.latitude
    maxLng = self.longitude
    until @pictures.length >= 6
      minLat -= step
      minLng -= step
      maxLat += step
      maxLng += step
      Rails.logger.debug "Picture Loop"
      @pictures = Picture.joins("LEFT JOIN picture_album_pictures ON pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON picture_album_pictures.picture_album_id = dives.album_id LEFT JOIN spots ON dives.spot_id = spots.id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) AND pictures.user_id IS NOT NULL", minLat, maxLat, minLng, maxLng).limit(10)
    end
    @pictures
  end

  def bestPicture
    @pictures = self.localPictures
    @bests=@pictures.where("great_pic = true")
    @bests.first
  end

  def dives
    @dives = []
    step = 0.1
    minLat = self.latitude
    minLng = self.longitude
    maxLat = self.latitude
    maxLng = self.longitude
    Rails.logger.debug "GeonamesCore minLng"
    until @dives.length > 6
      Rails.logger.debug "GeonamesCore #{minLng}"
      minLat -= step
      minLng -= step
      maxLat += step
      maxLng += step
      @dives += Dive.joins("LEFT JOIN spots ON dives.spot_id = spots.id").where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) AND privacy = 0", minLat, maxLat, minLng, maxLng).order("dives.time_in DESC")
    end
    @dives.uniq
  end

  def avgSurfTemp
    temps=0
    count=0
    @dives = self.localDives
    @dives.each do |d|
      if d.temp_surface_value != nil
        if d.temp_surface_unit=="F"
          temps+=(d.temp_surface_value-32)
        elsif d.temp_surface_unit=="C"
          temps+=(d.temp_surface_value)
        end
        count+=1
      end
    end
    if @dives.count>0
      temps/@dives.count
    else
      0
    end
  end

  def avgBotTemp
    temps=0
    count=0
    @dives = self.localDives
    @dives.each do |d|
      if d.temp_bottom_value!=nil
        if d.temp_bottom_unit=="F"
          temps+=(d.temp_bottom_value-32)
        elsif d.temp_surface_unit=="C"
          temps+=(d.temp_bottom_value)
        end
        count+=1 
      end
    end
    if count>0
      temps/count
    else
      0
    end
  end

  def avgDepth
    depths=0
    count=0
    @dives = self.localDives
    @dives.each do |d|
      if d.maxdepth_value!=nil && d.maxdepth_value > 9
        if d.maxdepth_unit=="ft"
          depths+=(d.maxdepth_value/ 3.2808)
        elsif d.maxdepth_unit=="m" && d.maxdepth_value > 3
          depths+=(d.maxdepth_value)
        end
        count+=1 
      end
    end
    if count>0
      depths/count
    else
      0
    end    end

  def localReviews
    @reviews=[]
    @shops=self.localShops
    @shops.each do |s|
      s.reviews.each do |r|
        @reviews.push r
      end
    end
    @reviews.uniq
  end

  def localAvg
    @reviews=self.localReviews
    total_percent_add = 0
    total_percent = 0

    @reviews.each do |s|
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

  def findSpots minLat, minLng, maxLat, maxLng
    if minLng > maxLng
      spots = Spot.where("score is not null and (spots.lat BETWEEN ? AND ?) AND not (spots.long BETWEEN ? AND ?)",minLat, maxLat,minLng, maxLng).order("score desc")
    else
      spots = Spot.where("score is not null and (spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)",minLat, maxLat,minLng, maxLng).order("score desc")
    end  
  end

  def localMark spots
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
  def localSpots
    @spots = []
    step = 0.1
    minLat = self.latitude
    minLng = self.longitude
    maxLat = self.latitude
    maxLng = self.longitude
    until @spots.length >= 15
      minLat -= step
      minLng -= step
      maxLat += step
      maxLng += step
      @spots = Spot.where("score is not null and (spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng).order("score DESC").limit(6)
    end
    @spots
  end

  def localNearby
  	#@current_country =GeonamesCountries.where("name = ?",self.country.cname).first
    #@nearby = GeonamesCore.where("country_code = ? AND feature_code=?",@current_country.ISO,"ADM1")
  end

  def localSpecies
    #TODO balance les especes croisés
    @species = []
  end

  def around
    @around = []
    
  end
  def localBestPictures
    @pictures = self.localPictures
    @best_pictures = @pictures.where("great_pic = true")
  end

  def shaken_id
      "g#{Mp.shake(self.id)}"
    end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "g"
        i =  Mp.deshake(code[1..-1])
      else
        i = Integer(code.to_s, 10)
      end
      if i.nil?
        raise DBArgumentError.new "Invalid ID"
      else
        target = GeonamesCore.find(i)
      end
    end

    def findPPL
=begin      
      result=nil
      step = 0.1
      minLat = self.latitude
      minLng = self.longitude
      maxLat = self.latitude
      maxLng = self.longitude
      until result != nil || step > 1
        Rails.logger.debug "UNTILLLLLLLLLLLLLLLL"
        minLat -= step
        minLng -= step
        maxLat += step
        maxLng += step
        step+=0.3
        result = GeonamesCore.where("(latitude BETWEEN ? and ? ) and (longitude BETWEEN ? and ?) and feature_code LIKE 'PPL'",minLat,maxLat,minLng,maxLng).first
      end
      result
=end  
      GeonamesCore.search " ", :geo => [latitude, longitude],:with=>{:ppl => true},:order => "geodist ASC"
    end

    def distanceFromGeonames point
=begin      dlon = point.longitude - self.longitude
      dlat = point.latitude - self.latitude
      a = (Math.sin(dlat/2)) ** 2 + Math.cos(point.latitude) * Math.cos(self.latitude) * (Math.sin(dlon/2)) ** 2 
      c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a) ) 
      return d = 6371000 * c
=end
      r =  6371 #kilometres
      latitude1 = (self.latitude * Math::PI / 180 )
      longitude1 = (self.latitude* Math::PI / 180 )
      latitude2 = (point.latitude * Math::PI / 180 )
      dlat = (self.latitude - point.latitude) * ( Math::PI / 180 )
      dlongitude = (self.longitude - point.longitude)* ( Math::PI / 180 )

      d = Math.acos( Math.sin(latitude1)*Math.sin(latitude2) + Math.cos(latitude1)*Math.cos(latitude2) * Math.cos(dlongitude) ) * r
    end

    def destinationLink
      #if self.country != nil
      geonames_country = GeonamesCountries.where("ISO like ?",self.country_code).first
      spot = nil
      step = 0.1
      minLat = self.latitude
      minLng = self.longitude
      maxLat = self.latitude
      maxLng = self.longitude
      until spot != nil
        minLat -= step
        minLng -= step
        maxLat += step
        maxLng += step
        spot = Spot.where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?)", minLat, maxLat, minLng, maxLng).first
      end

      return "/area/#{geonames_country.name.to_url}-#{geonames_country.shaken_id}/#{self.name.to_url}-#{self.shaken_id}"
=begin
      regions.each do |r|

       #r.update_bounds
       if r.nesw_bounds!=nil
        Rails.logger.debug "r id : #{r.id}"
        nesw = r.nesw_bounds
                    puts "4"

        if nesw != nil
          lat1 = nesw["northeast"]["lat"]
          lng1 = nesw["northeast"]["lng"]
          lat2 = nesw["southwest"]["lat"]
          lng2 = nesw["southwest"]["lng"]
              puts "3 : #{self.latitude} #{self.longitude}"

          if lat1 != nil && lat2 != nil && lng1 != nil && lng2 !=nil
            puts "#{lat1} > #{self.latitude} && #{lat2} < #{self.latitude} && #{lng1} > #{self.longitude} && #{lng2} < #{self.latitude}"
            if lat1 > self.latitude && lat2 < self.latitude && lng1 > self.longitude && lng2 < self.latitude
              puts "1"
              Rails.logger.debug "LINK true #{r.id}"
              #region = r
            else
              ""
            end
            ""
          end
          ""
        end
      end
      end
      nil
    end
=end
    end
end
