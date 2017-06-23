class V2::AreaPagesController < V2::ApplicationController
  def index
    @area = Area.find_by_url_name params[:vanity_url]
    if index_wrapper == nil
      render 'layouts/404.html', :layout => false, :status => 404
      return
    end
  end

  def index_with_id
    @area = Area.find_by_id params[:vanity_url]
    if index_wrapper == nil
      render 'layouts/404.html', :layout => false, :status => 404
      return
    end

    render "index"
  end

	def index_wrapper

    @shops_page_nb = 1
    shops_offset = 0
    @reviews_page_nb = 1
    reviews_offset = 0

    if params[:append] then
      append_content
      return true
    end

    @ga_page_category = "area"
    if @area == nil
      return nil
    end

    @reviews = @area.dives_order_by_overall_and_notes 5
    @reviews_more = @area.dives_order_by_overall_and_notes(6).size
    @pictures = @area.pictures_with_ratio(1.4, 2.4).to_a
    # if !@area.active?
    #   return nil
    # end
		
    @best_pictures = @area.best_pictures_with_ratio(1.4, 2.4).to_a
    @header_picture = @area.header_picture
    @pictures = @pictures - @best_pictures
		@shops = @area.shops 4
    @shops_more = @area.shops(5).size
		@mark = @area.mark
		@areas = @area.near_areas 5
    @avg_surf_temp = @area.average_temp_surface
    @avg_bot_temp = @area.average_temp_bottom
    @avg_depth = @area.average_depth
    if !@area.area_categories.nil?
      @species = @area.area_categories.order("count DESC").limit(4)
    else
      @species = []
    end

    months = [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]
    max_attendance = 0
    months.each do |month|
      if @area.send(month) > max_attendance
        max_attendance = @area.send(month)
      end
    end
    @attendance = Array.new
    i = 0
    months.each do |month|
      if max_attendance == 0
        @attendance[i] = 0
      else
        @attendance[i] = ((@area.send(month) * 50.0) / max_attendance)
      end
      i += 1
    end
	end

  def append_content
    nb_shops_page = 5
    nb_reviews_page = 5

    if params[:type] == 'shop' then
      if params[:page].to_i > 0 then
        @shops_page_nb = params[:page].to_i
        offset = nb_shops_page * (@shops_page_nb.to_i - 1)
      end
      @shops_page_nb = params[:page]
      shops = []
      shops = @area.shops(nb_shops_page, offset)
      render 'v2/area_pages/shops_append', :layout => false, :locals => {:shops => shops}

    elsif params[:type] == 'review' then
      if params[:page].to_i > 0 then
        @reviews_page_nb = params[:page].to_i
        offset = nb_reviews_page * (@reviews_page_nb.to_i - 1)
      end
      @reviews_page_nb = params[:page]
      reviews = []
      reviews = @area.dives_order_by_overall_and_notes(nb_reviews_page, offset)
      render 'v2/area_pages/reviews_append', :layout => false, :locals => {:reviews => reviews}
    end
  end

  def destination
    @country = nil
    @geonames_country = nil 
    @geonames_core = nil
    @region = nil
    @spot = nil


    if !params[:country].blank?
      @geonames_country = GeonamesCountries.where("iso like ?","%#{params[:country]}%").first rescue nil
    end



    [params[:country], params[:region], params[:place]].each do |p|
      next if p.nil?
      if shake = p.match(/\-(g[a-zA-Z0-9]+)$/)
        @spot = GeonamesCore.fromshake(shake[1])
      elsif shake = p.match(/\-(S[a-zA-Z0-9]+)$/)
        @spot = Spot.fromshake(shake[1])
      elsif shake = p.match(/\-(R[a-zA-Z0-9]+)$/)
        @region = Region.fromshake(shake[1])
      elsif shake = p.match(/\-(G[a-zA-Z0-9]+)$/)
        @geonames_country = GeonamesCountries.fromshake(shake[1])
      end
    end

    if (shake = params[:region].match(/\-(S[a-zA-Z0-9]+)$/) rescue nil) && !@geonames_country.nil?
      spot = Spot.fromshake(shake[1])
      redirect_to "/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}/#{spot.region.name.to_url}-#{spot.region.shaken_id}/#{spot.name.to_url}-#{spot.shaken_id}"
      return
    end


    if !@geonames_country.nil? && @region.nil?
      @country = Country.where("ccode like ?",@geonames_country.ISO).first
      nesw = JSON.parse @country.nesw_bounds
      @lat1 = nesw["northeast"]["lat"]
      @lng1 = nesw["northeast"]["lng"]
      @lat2 = nesw["southwest"]["lat"]
      @lng2 = nesw["southwest"]["lng"]
      @zoom = 5 #(nesw["northeast"]["lng"] - nesw["southwest"]["lng"] ).floor - 1
      @name = @geonames_country.name

      @country_name = @geonames_country.name
      Rails.logger.debug "OPTI HEADER PICTURE #{Time.now}"
      @header = @geonames_country.headerPicture @country.id
      #@reviews = @geonames_country.localReviews
      Rails.logger.debug "OPTI DIVES REVIEWS #{Time.now}"
      @reviews = @geonames_country.localDivesReviews(@lat2, @lng2, @lat1, @lng1)
      Rails.logger.debug "OPTI MARK #{Time.now}"
=begin
      Rails.cache.fetch("#{@country_name}", expires_in: 24.hours) do
        @geonames_country.localMark
      end
      @mark = Rails.cache.fetch("#{@country_name}")
=end
      @mark = @geonames_country.localMark
      Rails.logger.debug "#{@mark} mark"

      Rails.logger.debug "OPTI ROUTE #{Time.now}"
      @route = "<a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}\">#{@name}</a>"
      Rails.logger.debug "OPTI SPOTS #{Time.now}"
      @spots = @geonames_country.localSpots(@country.id, @lat2, @lng2, @lat1, @lng1)
      Rails.logger.debug "OPTI WIKI #{Time.now}"

      @about = @country.wiki.data rescue nil

      Rails.logger.debug "OPTI DIVES #{Time.now}"
      @dives = @geonames_country.localDives(@lat2, @lng2, @lat1, @lng1)
      Rails.logger.debug "OPTI HEADER SHOPS #{Time.now} "
      @shops = @geonames_country.localShops
      Rails.logger.debug "OPTI HEADER REGIONS #{Time.now}"
#     @regions = Region.joins("LEFT join countries_regions on countries_regions.country_id=#{@country.id}").where("best_pic_ids is not null")
      @regions=[]
      
      @spots[0..19].each do |s|
        if s.region.best_pics.count==0
          s.region.update_best_pics!
        end
        @regions.push s.region
      end
      @regions.uniq!

      Rails.logger.debug "OPTI END #{Time.now}"

    elsif !@region.nil? && @spot.nil?
      @name = @region.name
      @country_name = @geonames_country.name
      @country = Country.where("ccode like ?",@geonames_country.ISO).first
      @geonames_core = GeonamesCore.joins("LEFT JOIN countries ON geonames_cores.country_code = countries.ccode").where("countries.ccode like ? AND geonames_cores.name like ?",@country.ccode, @region.name).first
      @region.update_bounds
      @dives = @region.localDives @country.id
      nesw = @region.nesw_bounds
      if !@region.best_pics.empty?
        @header= @region.best_pic 
      else
        @header = @region.pictures.last
      end
      @reviews = @region.localDivesReviews @dives
      @route ="<a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}\">#{@geonames_country.name}</a> > 
      <a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}/#{@region.name.to_url}-#{@region.shaken_id}\">#{@region.name}</a>"
      
      @spots = []
      @shops = []
      @dives.each do |d|
        if d.spot.best_pics.count>0
          @spots.push d.spot
        end
        @shops.push(d.shop)
      end
      @spots.uniq!
      @mark = @region.mark @spots
      @shops.uniq!
      @arounds=@region.spots.joins("LEFT JOIN countries on country_id=countries.id").where("score is not null and countries.ccode=?",@geonames_country.ISO).order("score DESC")
    elsif !@spot.nil?
      
      if @spot.class == GeonamesCore
        x=@spot.latitude
        y=@spot.longitude
        #@mark=@spot.mark
        picts=@spot.bestPicture
        if picts!=nil
          @header = picts
        end

      elsif @spot.class == Spot
        x=@spot.lat
        y=@spot.long
        @mark = @spot.mark
        #@header = @spot.best_pic
        picts=@spot.best_pics.first
        if picts!=nil
          @header = picts
        end
      else
        ##render 404

      end

      nesw = @region.nesw_bounds
#      @lat1 = nesw["northeast"]["lat"]
#      @lng1 = nesw["northeast"]["lng"]
#      @lat2 = nesw["southwest"]["lat"]
#      @lng2 = nesw["southwest"]["lng"]
      @route ="<a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}\">#{@geonames_country.name}</a> > 
      <a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}/#{@region.name.to_url}-#{@region.shaken_id}\">#{@region.name}</a> >
      <a href=\"/area/#{@geonames_country.name.to_url}-#{@geonames_country.shaken_id}/#{@region.name.to_url}-#{@region.shaken_id}/#{@spot.name.to_url}-#{@spot.shaken_id}\">#{@spot.name}</a>"
      @name=@spot.name
      @dives = @spot.dives
      @reviews=[]
      @shops=[]
      @spots=[]
      @arounds=@region.spots.joins("LEFT JOIN countries on country_id=countries.id").where("score is not null and countries.ccode=?",@geonames_country.ISO).order("score DESC")

      @dives.each do |d|
        if d.shop!=nil
          @shops.push d.shop
          @reviews.push(*d.shop.reviews)
          @spots.push(d.spot)
        end
      end
      @spots.uniq!
      @shops.uniq!
      if @spot.class == GeonamesCore
        @mark = @spot.localMark @spots
      end
      @area = Area.where("(? BETWEEN minLat and maxLat) and (? BETWEEN minLng and maxLng) and geonames_core_id is not null",x,y).first
    end
    render 'v2/area_pages/destination/destination'
  end
end
