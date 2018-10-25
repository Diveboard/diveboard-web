require 'nokogiri'
require 'open-uri'
require 'net/http'
require "geoip"
require 'boolean_compare'

class SearchController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :signup_popup_hidden #init the graph connection and everyhting user related
  layout 'main_layout'

  def explore
    @pagename ="EXPLORE"
    @ga_page_category = "explore"

    begin
      if params[:vanity] then
        panel2 = User.where(:vanity_url => params[:vanity]).first
      elsif params[:shop_vanity] then
        panel2 = Shop.joins(:user_proxy).where('users.vanity_url' => params[:shop_vanity]).first
      elsif params[:dive_id] then
        panel2 = Dive.fromshake(params[:dive_id])
      elsif params[:spot_blob] then
        panel2 = Spot.fromshake(params[:spot_blob].match(/\-([a-zA-Z0-9]+)$/)[1])
      elsif params[:location_blob] then
        panel2 = Location.fromshake(params[:location_blob].match(/\-([a-zA-Z0-9]+)$/)[1])
      elsif params[:region_blob] then
        panel2 = Region.fromshake(params[:region_blob].match(/\-([a-zA-Z0-9]+)$/)[1])
      elsif params[:country_blob] then
        panel2 = Country.where(:blob => params[:country_blob]).first unless Country.where(:blob => params[:country_blob]).first.id == 1
      end

      @meta_obj = panel2
      panel2.userid = @user.id rescue nil ## this tells the model to switch context as a logged user - a bit clunky but makes life easier - if I'm a user I wanna see y content

    rescue
      @meta_obj = nil
    end

    Rails.logger.debug "panel2: #{panel2.inspect} ; meta_obj: #{@meta_obj.inspect}"

    begin
      search_address = ""
      if !params[:search_address].nil? then
        search_address = params[:search_address]
      elsif !params[:lat].nil? && !params[:lng].nil? then
        initial_location = {"latitude" => params[:lat].to_f, "longitude" => params[:lng], "zoom" => 6}
        initial_location['zoom'] = params[:zoom] unless params[:lng].nil?
      elsif !panel2.nil? then
        if panel2.class.to_s == "Spot" then initial_location = {"latitude" => panel2.lat, "longitude" => panel2.lng, 'zoom' => panel2.zoom}
        elsif panel2.class.to_s == "Shop" then initial_location = {"latitude" => panel2.lat, "longitude" => panel2.lng, 'zoom' => 10}
        elsif panel2.class.to_s == "Dive" then initial_location = {"latitude" => panel2.spot.lat, "longitude" => panel2.spot.lng, 'zoom' => panel2.spot.zoom}
        elsif ['User', 'Region', 'Country', 'Location'].include? panel2.class.to_s then
          lat={}
          lng={}
          panel2.spots.each do |spot|
            #reject spots we're not sure of
            next if spot.lat.round(4).to_f == 0 && spot.lng.round(4).to_f == 0
            next unless spot.flag_moderate_private_to_public.nil?

            lat[:min] = spot.lat if lat[:min].nil? || spot.lat < lat[:min]
            lat[:max] = spot.lat if lat[:max].nil? || spot.lat > lat[:max]

            lng[:min] = spot.lng if lng[:min].nil?
            lng[:max] = spot.lng if lng[:max].nil?

            spot_lng = spot.lng
            if spot_lng < lng[:min] then
              if spot_lng+360 > lng[:max] then
                #need to extend
                  if spot_lng+360 - lng[:max] > lng[:min]-spot_lng then
                    lng[:min] = spot_lng
                  else
                    lng[:max] = spot_lng+360
                  end
              end #else is already included
            elsif spot_lng > lng[:max]
              if spot_lng-360 < lng[:min]
                #need to extend
                if spot_lng - lng[:max] > lng[:min] - (spot_lng-360) then
                    lng[:min] = spot_lng-360
                else
                    lng[:max] = spot_lng
                end
              end
            end
          end

          if lng[:min].nil? && panel2.is_a?(Country) then
            begin
              lng[:min] = panel2.bounds['southwest']['lng']
              lng[:max] = panel2.bounds['northeast']['lng']
              lat[:min] = panel2.bounds['southwest']['lat']
              lat[:max] = panel2.bounds['northeast']['lat']
            rescue
            end
          end

          if !lng[:min].nil? then
            if lng[:max]-lng[:min] > 360 then
              initial_location = {"lat_max" => lat[:max], "lat_min" =>lat[:min], "lng_min" => -179, "lng_max" => 179}
            else
              initial_location = {"lat_max" => lat[:max], "lat_min" =>lat[:min], "lng_min" => lng[:min], "lng_max" => lng[:max]}
            end
          end
        end
      end

      if initial_location.nil? then
         # geoip = GeoIP.new('db/geoip/GeoLiteCity.dat')
         # @user_location = geoip.city(request.remote_ip)
         # @initial_location = {"latitude" => @user_location.latitude, "longitude" => @user_location.longitude}
        initial_location = [
          {"latitude" => 19.325, "longitude" => -81.171, 'zoom' => 11}, #Cayman islands
          {"latitude" => -21.7, "longitude" => 145.2, 'zoom' => 5}, #australie
          {"latitude" => 20.29, "longitude" => -156.56, 'zoom' => 8}, #Hawaii
          {"latitude" => 27.82, "longitude" => -81.43, 'zoom' => 6}, #floride
          {"latitude" => 14.94, "longitude" => -65.62, 'zoom' => 6}, #east caribbean (rep dom, guadeloupe)
          {"latitude" => 18.48, "longitude" => -85.96, 'zoom' => 7}, #west caribbean (cozumel, belize, honduras)
          {"latitude" => 27.13, "longitude" => 33.79, 'zoom' => 7}  # egypt
        ][(7*rand).floor]
      end
    rescue
      logger.warn $!
      logger.warn $!.backtrace.join("\n")
      initial_location = {"latitude" => 21.125169323467198, "longitude" => -77.09304003906254, 'zoom' => 7}
    end

    @gmapskey = GOOGLE_MAPS_API
    
    render :locals => {:initial_location => initial_location, :panel2 => panel2}
  end

  def explore_missing_asset
    filename = "public/assets/explore/#{params[:level]}/#{params[:asset_name]}"
    FileUtils.mkdir_p(File.dirname(filename))
    File.open(filename, "w") { |file| file.write '{}' }
    response.headers['Cache-Control'] = "public, must-revalidate, proxy-revalidate"
    response.headers['Access-Control-Allow-Origin'] = "http://#{ROOT_DOMAIN}"
    render :file => filename, :layout => false
  end

  def search_spot_coord
    if params[:lat_min].nil? || params[:long_min].nil? || params[:lat_max].nil? || params[:long_max].nil? then
      render :json => {:success => false, :error => "Argument missing" }
      return
    end

    select_close = ""

    logger.debug "Latitude requested : #{params[:lat_min]} - #{params[:lat_max]}"
    if params[:lat_min].to_f < params[:lat_max].to_f then
      select_close += " spots.lat between :lat_min and :lat_max"
    else
      select_close += " (spots.lat > :lat_min or spots.lat < :lat_max)"
    end

    logger.debug "Longitude requested : #{params[:long_min]} - #{params[:long_max]}"
    if params[:long_min].to_f < params[:long_max].to_f then
      select_close += " and spots.long between :long_min and :long_max"
    else
      select_close += " and (spots.long > :long_min or spots.long < :long_max)"
    end

    search_and_render_spots(select_close,
                    { :lat_min => params[:lat_min].to_f,
                    :lat_max => params[:lat_max].to_f,
                    :long_min => params[:long_min].to_f,
                    :long_max => params[:long_max].to_f })

  end

  def search_spot_text
    where_close = " true "
    attributes = {}

    #Using multi-word search
    if !params[:term].nil? then
      i=0
      params[:term].gsub(/([0-9]+)/,' \0 ').split(/[ ,;:\t\n\r]+/).each { |word|
        if (/^location=(.*)$/ === word) then
          where_close += "and (locations.name = :param#{i})"
          attributes[:"param#{i}"] = "#{$1.gsub('_', ' ')}"
        elsif (/^region=(.*)$/ === word) then
          where_close += "and (regions.name = :param#{i})"
          attributes[:"param#{i}"] = "#{$1.gsub('_', ' ')}"
        elsif (/^country=(.*)$/ === word) then
          where_close += "and (countries.cname = :param#{i})"
          attributes[:"param#{i}"] = "#{$1.gsub('_', ' ')}"
        else
          where_close += "and (spots.name like :param#{i} OR locations.name like :param#{i} OR regions.name like :param#{i} or countries.cname LIKE :param#{i})"
          attributes[:"param#{i}"] = "%#{word}%"
        end
        i+=1
      }
    end

    #Ordering by distance if lat/lng provided
    order_close = nil
    if params[:lat] && params[:lng] then
      lat = params[:lat].to_f*Math::PI/180
      lng = params[:lng].to_f*Math::PI/180
      order_close = "ACOS(SIN(spots.lat*PI()/180)*SIN(#{lat})+COS(spots.lat*PI()/180)*COS(#{lat})*COS((spots.`long`*PI()/180)-#{lng}))*6371"
    end

    #filtering by min/max if provided
    if !params[:latSW].blank? && !params[:latNE].blank? && !params[:lngSW].blank? && !params[:lngNE].blank? then
      logger.debug "Latitude requested : #{params[:latSW]} - #{params[:latNE]}"
      if params[:latSW].to_f < params[:latNE].to_f then
        where_close += " AND spots.lat between :latSW and :latNE "
      else
        where_close += " AND (spots.lat > :latSW or spots.lat < :latNE) "
      end

      logger.debug "Longitude requested : #{params[:lngSW]} - #{params[:lngNE]}"
      if params[:lngSW].to_f < params[:lngNE].to_f then
        where_close += " and spots.long between :lngSW and :lngNE "
      else
        where_close += " and (spots.long > :lngSW or spots.long < :lngNE) "
      end

      attributes[:latNE] = params[:latNE].to_f
      attributes[:latSW] = params[:latSW].to_f
      attributes[:lngNE] = params[:lngNE].to_f
      attributes[:lngSW] = params[:lngSW].to_f
    end


    search_and_render_spots(where_close, attributes, order_close)

  end

  def search_and_render_spots(where_close, attributes, order_close=nil)
    select_close = "SELECT spots.id, spots.name, spots.lat, spots.long, locations.name AS location, regions.name AS region, countries.cname AS cname, count(dives.id) AS dive_count
                    FROM `spots`
                      LEFT JOIN locations ON spots.location_id = locations.id
                      LEFT JOIN regions ON spots.region_id = regions.id
                      LEFT JOIN countries ON spots.country_id = countries.id
                      LEFT JOIN dives ON dives.spot_id = spots.id and dives.privacy=0
                    WHERE spots.id != 1
                      and spots.moderate_id is null and spots.redirect_id is null
                      and (spots.flag_moderate_private_to_public IS NULL OR spots.private_user_id = :user_id)
                      AND (#{where_close})
                    GROUP BY spots.id
                    ORDER BY "
    select_close += " #{order_close}, " if order_close
    select_close += " count(distinct dives.id) DESC, spots.name "
    select_close += " limit 40 "

    attributes[:user_id] = @user.id rescue nil

    @result = Media.select_all_sanitized(
                  select_close,
                  attributes)

    render :text => {"success" => true, "spots" => @result}.to_s.gsub('=>', ':').gsub('nil', 'null'), :content_type=>"application/json"
  end



  def search_region_text
    where_close = " true "
    attributes = {}

    #Using multi-word search
    variable_where = "true"
    if !params[:term].nil? then
      i=0
      params[:term].gsub(/([0-9]+)/,' \0 ').split(/[ ,;:\t\n\r]+/).each { |word|
        variable_where = "%s like :param#{i}"
        attributes[:"param#{i}"] = "%#{word}%"
        i+=1
      }
    end

    #Ordering by distance if lat/lng provided
    order_close = nil
    if params[:lat] && params[:lng] then
      lat = params[:lat].to_f*Math::PI/180
      lng = params[:lng].to_f*Math::PI/180
      where_close += " AND ABS(spots.lat - #{params[:lat].to_f}) < :latlng_delta AND ABS(spots.`long` - #{params[:lng].to_f}) < :latlng_delta "
      order_close = "ACOS(SIN(spots.lat*PI()/180)*SIN(#{lat})+COS(spots.lat*PI()/180)*COS(#{lat})*COS((spots.`long`*PI()/180)-#{lng}))*6371"
    end

    #filtering by min/max if provided
    if !params[:latSW].blank? && !params[:latNE].blank? && !params[:lngSW].blank? && !params[:lngNE].blank? then
      logger.debug "Latitude requested : #{params[:latSW]} - #{params[:latNE]}"
      if params[:latSW].to_f < params[:latNE].to_f then
        where_close += " AND spots.lat between :latSW and :latNE "
      else
        where_close += " AND (spots.lat > :latSW or spots.lat < :latNE) "
      end

      logger.debug "Longitude requested : #{params[:lngSW]} - #{params[:lngNE]}"
      if params[:lngSW].to_f < params[:lngNE].to_f then
        where_close += " and spots.long between :lngSW and :lngNE "
      else
        where_close += " and (spots.long > :lngSW or spots.long < :lngNE) "
      end

      attributes[:latNE] = params[:latNE].to_f
      attributes[:latSW] = params[:latSW].to_f
      attributes[:lngNE] = params[:lngNE].to_f
      attributes[:lngSW] = params[:lngSW].to_f
    end


    attributes[:latlng_delta] = 2
    attributes[:user_id] = @user.id rescue nil

    #adjusting the query radius depending on how many spots in the area
    select_delta_query = "SELECT COUNT(*) from spots
                          WHERE spots.id != 1
                            and spots.moderate_id is null and spots.redirect_id is null
                            and (spots.flag_moderate_private_to_public IS NULL OR spots.private_user_id = :user_id)
                            AND (#{where_close})"
    5.times do |t|
      nb = Media.select_value_sanitized(select_delta_query, attributes)
      break if nb > 0
      attributes[:latlng_delta] *= 2
    end
    Rails.logger.debug "Using latlng_delta of #{attributes[:latlng_delta]}"


    select_close = "SELECT locations.id as id, locations.name as name
                    FROM `spots`
                      JOIN locations ON spots.location_id = locations.id
                    WHERE spots.id != 1
                      and spots.moderate_id is null and spots.redirect_id is null
                      and (spots.flag_moderate_private_to_public IS NULL OR spots.private_user_id = :user_id)
                      AND (#{where_close}) AND #{variable_where % 'locations.name'}
                    GROUP BY locations.id
                    ORDER BY "
    select_close += " #{order_close}, " if order_close
    select_close += " count(distinct spots.id) DESC "
    select_close += " limit 10 "


    @locations = Media.select_all_sanitized(
                  select_close,
                  attributes)



    select_close = "SELECT regions.id as id, regions.name as name
                    FROM `spots`
                      JOIN regions ON spots.region_id = regions.id
                    WHERE spots.id != 1
                      and spots.moderate_id is null and spots.redirect_id is null
                      and (spots.flag_moderate_private_to_public IS NULL OR spots.private_user_id = :user_id)
                      AND (#{where_close}) AND #{variable_where % 'regions.name'}
                    GROUP BY regions.id
                    ORDER BY "
    select_close += " #{order_close}, " if order_close
    select_close += " count(distinct spots.id) DESC "
    select_close += " limit 10 "


    @regions = Media.select_all_sanitized(
                  select_close,
                  attributes)



    select_close = "SELECT countries.id as id, countries.ccode as code, countries.cname as name
                    FROM `spots`
                      JOIN countries ON spots.country_id = countries.id
                    WHERE spots.id != 1
                      and spots.moderate_id is null and spots.redirect_id is null
                      and (spots.flag_moderate_private_to_public IS NULL OR spots.private_user_id = :user_id)
                      AND (#{where_close}) AND #{variable_where % 'countries.cname'}
                    GROUP BY countries.id
                    ORDER BY "
    select_close += " #{order_close}, " if order_close
    select_close += " count(distinct spots.id) DESC "
    select_close += " limit 10 "


    @countries = Media.select_all_sanitized(
                  select_close,
                  attributes)






    render :json => {"success" => true, "locations" => @locations, 'regions' => @regions, 'countries' => @countries}

  end





 def search_shop_text
    where_close = " true "
    attributes = {}

    #Using multi-word search
    if !params[:term].nil? then
      i=0
      params[:term].gsub(/([0-9]+)/,' \0 ').split(/[ ,;:\t\n\r]+/).each { |word|
        if (/^country=(.*)$/ === word) then
          where_close += "and (countries.cname = :param#{i})"
          attributes[:"param#{i}"] = "#{$1.gsub('_', ' ')}"
        else
          where_close += "and (shops.name like :param#{i} or countries.cname LIKE :param#{i})"
          attributes[:"param#{i}"] = "%#{word}%"
        end
        i+=1
      }
    end

    #Ordering by distance if lat/lng provided
    order_close = nil
    if params[:lat] && params[:lng] then
      lat = params[:lat].to_f*Math::PI/180
      lng = params[:lng].to_f*Math::PI/180
      order_close = "ACOS(SIN(shops.lat*PI()/180)*SIN(#{lat})+COS(shops.lat*PI()/180)*COS(#{lat})*COS((shops.`lng`*PI()/180)-#{lng}))*6371"
    end

    #filtering by min/max if provided
    if !params[:latSW].blank? && !params[:latNE].blank? && !params[:lngSW].blank? && !params[:lngNE].blank? then
      logger.debug "Latitude requested : #{params[:latSW]} - #{params[:latNE]}"
      if params[:latSW].to_f < params[:latNE].to_f then
        where_close += " AND shops.lat between :latSW and :latNE "
      else
        where_close += " AND (shops.lat > :latSW or shops.lat < :latNE) "
      end

      logger.debug "Longitude requested : #{params[:lngSW]} - #{params[:lngNE]}"
      if params[:lngSW].to_f < params[:lngNE].to_f then
        where_close += " and shops.lng between :lngSW and :lngNE "
      else
        where_close += " and (shops.lng > :lngSW or shops.lng < :lngNE) "
      end

      attributes[:latNE] = params[:latNE].to_f
      attributes[:latSW] = params[:latSW].to_f
      attributes[:lngNE] = params[:lngNE].to_f
      attributes[:lngSW] = params[:lngSW].to_f
    end


    search_and_render_shops(where_close, attributes, order_close)

  end


  def search_and_render_shops(where_close, attributes, order_close=nil)
    select_close = "SELECT shops.id, shops.name, shops.lat, shops.lng, countries.cname AS cname, count(dives.id) AS dive_count
                    FROM `shops`
                      LEFT JOIN countries ON shops.country_code = countries.ccode
                      LEFT JOIN dives ON dives.shop_id = shops.id and dives.privacy=0
                    WHERE shops.id != 1
                      and (shops.flag_moderate_private_to_public IS NULL OR shops.private_user_id = :user_id)
                      AND (#{where_close})
                    GROUP BY shops.id
                    ORDER BY "
    select_close += " #{order_close}, " if order_close
    select_close += " count(distinct dives.id) DESC, shops.name "
    select_close += " limit 40 "

    attributes[:user_id] = @user.id rescue nil

    @result = Media.select_all_sanitized(
                  select_close,
                  attributes)

    @result.each do |shop|
      shop['shaken_id'] = "K#{Mp.shake(shop['id'])}"
    end

    render :json => {"success" => true, "shops" => @result}
  end











  def search_diver_coord
    if params[:lat_min].nil? || params[:long_min].nil? || params[:lat_max].nil? || params[:long_max].nil? then
      render :json => {:success => false, :error => "Argument missing" }
      return
    end

    if params[:lat_min].to_f < params[:lat_max].to_f then
      where_close = " spots.lat between :lat_min and :lat_max"
    else
      where_close = " (spots.lat > :lat_min or spots.lat < :lat_max)"
    end

    if params[:long_min].to_f < params[:long_max].to_f then
      where_close += " and spots.long between :long_min and :long_max"
    else
      where_close += " and (spots.long > :long_min or spots.long < :long_max)"
    end

    search_and_render_diver(where_close,
                  { :lat_min => params[:lat_min].to_f,
                    :lat_max => params[:lat_max].to_f,
                    :long_min => params[:long_min].to_f,
                    :long_max => params[:long_max].to_f },
                  20)
  end


  def search_diver_text
    if params[:term].nil? then
      render :json => {:success => false, :error => "Argument missing" }
      return
    end

    if params[:term].length < 3 then
      render :json => {:success => false, :error => "Argument too short" }
      return
    end


    where_close = "true"
    args = {}
    i=0

    #Using multi-word search
    params[:term].gsub(/([0-9]+)/,' \0 ').split(/[ ,;:\t\n\r]+/).each { |word|
      where_close += " and nickname like :param#{i}"
      args[:"param#{i}"] = "%#{word}%"
    }

    search_and_render_diver(where_close, args, 20)
  end


  def search_and_render_diver(where, arg, limit)

    where_close = "dives.privacy = 0 and spots.id != 1 and spots.moderate_id is null"
    where_close += " and ("+where+")"

    list_of_users = Dive
                .includes(:spot)
                .joins(:user)
                .where(where_close, arg)
                .select(:user_id)
                .group(:user_id)
                .order("count(dives.id) DESC")
                .limit(limit)

    logger.debug "List of users : #{list_of_users.collect(&:user_id)}"

    @result = User
                .includes(:dives)
                .includes(:dives => :spot)
                .includes(:dives => {:spot => :country})
                .where("dives.privacy = 0 and spots.id != 1 and users.id in(:list)", {:list => list_of_users.collect(&:user_id)})

    render :json => {
        :success => true,
        :divers => @result.to_json(
            :methods => [:picture, :picture_small, :qualifications],
            :only => [:id, :nickname, :vanity_url, :picture, :qualifications],
            :include => {
                :dives => {
                    :only => [ :duration, :maxdepth, :notes, :time_in, :temp_bottom, :temp_surface, :id, ],
                    :methods => [ :featured_picture, :permalink ],
                    :include => {
                        :spot => {
                            :only => []
                            }
                        }
                    }
                }
            )
        }
  end

  def search_diver_spot
    if params[:spot_id].nil? then
      render :json => {:success => false, :error => "Argument missing" }
      return
    end

    @result = User
        .includes(:dives)
        .where("dives.spot_id" => params[:spot_id].to_i)
        .order(:time_in)
        .group(:user_id)

    render :json => {
        :success => true,
        :divers => @result.to_json(
            :methods => [:picture, :picture_small, :qualifications],
            :only => [:id, :nickname, :vanity_url, :picture, :qualifications],
            :include => {
                :dives => {
                    :only => [ :duration, :maxdepth, :notes, :time_in, :temp_bottom, :temp_surface, :id, ],
                    :methods => [ :featured_picture, :permalink ]
                    }
                }
            )
        }
  end




  def explore_all
    data = {}
    data[:spots] = {}
    logger.info "Generating Assets explore : START"
    logger.info "Generating Assets explore : Spots"

    Spot.includes([:country, :location, :region, :dives, :dives => :user]).all.each do |o|
      next unless o.flag_moderate_private_to_public.nil?
      begin
        api_data = o.to_api :search_light
        data[:spots][o.id] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end

    logger.info "Generating Assets explore : Users"
    data[:users] = {}
    User.includes([:dives, :spots]).all.each do |o|
      begin
        api_data = o.to_api :search_light
        data[:users][o.id] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end


    logger.info "Generating Assets explore : Dives"
    data[:dives] = {}
    Dive.includes([:user, :dive_gears, :dive_using_user_gears, :spot, :eolcnames, :eolsnames, {:eolcnames => :eolsname}]).where('privacy is null OR privacy = 0').all.each do |o|
      next unless o.spot.flag_moderate_private_to_public.nil?
      begin
        api_data = o.to_api :search_light
        data[:dives][o.id] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end

    logger.info "Generating Assets explore : Countries"
    data[:countries] = {}
    Country.all.each do |cnt|
      begin
        api_data = cnt.to_api :search_light
        data[:countries][cnt.blob] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end

    logger.info "Generating Assets explore : Regions"
    data[:regions] = {}
    Region.all.each do |cnt|
      begin
        api_data = cnt.to_api :search_light
        data[:regions][cnt.blob] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end

    logger.info "Generating Assets explore : Locations"
    data[:locations] = {}
    Location.all.each do |cnt|
      begin
        api_data = cnt.to_api :search_light
        data[:locations][cnt.blob] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end

    logger.info "Generating Assets explore : Shops"
    data[:shops] = {}
    Shop.includes([:dives]).all.each do |cnt|
      begin
        api_data = cnt.to_api :search_light
        data[:shops][cnt.id] = api_data unless api_data.nil?
      rescue
        Rails.logger.warn $!.message
        Rails.logger.debug $!.backtrace
      end
    end

    logger.info "Generating Assets explore : DONE"
    render :json => {
      :success => true,
      :result => data
    }
    return
  end


  def get_full_detail
    #full is the list of items to give full detail
    #remain is the list of items to give light detail
    full = {}
    remain = {}
    data = {}
    errors = []

    #a proc is needed instead of a 'def' to keep the scope
    store_detail = Proc.new do |stock, category, level, &block|
      stock[category].each do |id|
        #do not overwrite an item since it probably has less details in the new version
        if data[category][id.to_s].nil? then
          begin
            my_object = block.yield(id)
            my_object.userid = @user.id rescue nil if my_object.respond_to? :userid= ##this will ensure that the data (like wiki) are the one set by the user ifmore rencent then moderated data
            json = my_object.to_api level
            data[category][my_object.id.to_s] = json
            data[category][my_object.shaken_id] = json if my_object.respond_to? :shaken_id
          rescue
            logger.debug $!
            logger.debug $!.backtrace.join("\n")
            errors.push({:item => category, :id => id})
          end
        end
      end
    end

    [:dives, :users, :spots, :pictures, :countries, :locations, :regions, :pictures, :shops].each do |category|
      full[category] = []
      remain[category] = []
      data[category] = {}
      full[category] += params[category] unless params[category].nil?
    end

    store_detail.call(full, :countries, :search_full) { |id|
      Country.fromshake(id)
    }

    store_detail.call(full, :locations, :search_full) { |id|
      Location.fromshake(id)
    }

    store_detail.call(full, :regions, :search_full) { |id|
      Region.fromshake(id)
    }

    store_detail.call(full, :users, :search_full) { |id|
      user = User.fromshake(id)
      full[:pictures] += user.dive_picture_ids
      remain[:dives] += user.public_dive_ids
      remain[:spots] += user.public_spot_ids
      user
    }

    store_detail.call(full, :dives, :search_full) { |id|
      dive = Dive.fromshake(id)
      full[:pictures] += dive.picture_ids
      full[:spots] += [dive.spot.id]
      remain[:users] += [dive.user.id]
      dive
    }

    store_detail.call(full, :spots, :search_full) { |id|
      spot = Spot.fromshake(id)
      full[:pictures] += spot.picture_ids
      remain[:dives] += spot.dives.reject do |d| d.privacy==1 end .map(&:id).uniq
      remain[:users] += spot.dives.reject do |d| d.privacy==1 end .map(&:user_id).uniq
      remain[:countries] += [spot.country.id] unless spot.country.nil?
      remain[:locations] += [spot.location.id] unless spot.location.nil?
      remain[:regions] += [spot.region.id] unless spot.region.nil?
      remain[:shops] += spot.shop_ids
      spot
    }

    store_detail.call(full, :pictures, :search_full) { |id|
      Picture.fromshake(id)
    }


    #give light details on the rest
    store_detail.call(remain, :dives, :search_light) { |id|
      Dive.fromshake(id)
    }

    store_detail.call(remain, :users, :search_light) { |id|
      User.fromshake(id)
    }

    store_detail.call(remain, :spots, :search_light) { |id|
      Spot.fromshake(id)
    }

    store_detail.call(remain, :pictures, :search_light) { |id|
      Picture.fromshake(id)
    }

    store_detail.call(remain, :countries, :search_light) { |id|
      Country.fromshake(id)
    }

    store_detail.call(remain, :locations, :search_light) { |id|
      Location.fromshake(id)
    }

    store_detail.call(remain, :regions, :search_light) { |id|
      Region.fromshake(id)
    }

    store_detail.call(remain, :shops, :search_light) { |id|
      Shop.fromshake(id)
    }

    #Removing keys with shaken id, because explore would duplicate spots in lists
    data.keys.each do |category|
      keys = data[category].keys
      keys.reject! do |k| !k.match(/[A-Za-z]/) end
      data[category] = data[category].except *keys
    end

    Rails.logger.debug render :json => {:success => true, :result => data}
  end



  def fishmap

    if params[:snid].nil? then
      render :text => "Missing parameter", :layout => false
      return
    end

    @map = Eolsname.find(params[:snid].to_i).frequencies

    render :layout => false, :content_type => "application/vnd.google-earth.kml+xml"

  end

  def search
    @pagename ="SEARCH"
    @ga_page_category = "search"
    @ga_custom_url = "/search"
    @search_text = params[:s].to_s.downcase
    @search_params = params.slice :s, :more, :page

    @location = GeonamesCore.search Riddle::Query.escape(@search_text), :with => {:ppl => true},:order_by=>'population desc' ,:group_by => :country_code
    if @location.empty?
      @location = Array.new
      @distances = Array.new
      @points = GeonamesCore.search Riddle::Query.escape(@search_text)
      @points[0..3].each do |p|
        ppl = p.findPPL.first
        @distances.push p.distanceFromGeonames ppl
        @location.push ppl
      end
    end
    if @location.empty?
      @location= Array.new
      @distances = Array.new
      @points = Array.new
      @search_text = @search_text.split(' ').reject{|w| w.length < 4 }.join(' ') 
      @points = GeonamesCore.search @search_text.gsub(" "," | ") ,:match_mode => :boolean
      @points[0..3].each do |p|
        ppl = p.findPPL.first
        if !ppl.nil?
          @distances.push p.distanceFromGeonames ppl
          @location.push ppl
        end
      end
    end
    @location.uniq!
    #geonames_cores = GeonamesCore.where("name like ? and feature_code like 'PPL%'","%"+@search_text+"%").order("population DESC")
   # geonames_cores = GeonamesCore.search @search_text
    #@location = GeonamesCore.find_by_sql("SELECT * FROM (select * from diveboard.geonames_cores  where name like "+"'%"+@search_text+"%'" +" and feature_code like 'PPL%' order by population DESC ) as c group by country_code order by population DESC")
#    regions = Region.where("name like ?",@search_text).uniq
#    geonames_coutries = GeonamesCountries.where("name like ?",@search_text).uniq
    #if geonames_cores!=nil
     # @location.push(*geonames_cores)
    #end

    
    @rounds= []
    @countries = []
    @countries_count = 0
    @shops = []
    @shops_count = 0
    @users = []
    @users_count = 0
    @spots = []
    @spots_count = 0
    @posts = []
    @posts_count = 0

    @per_page = 42
    @show_count = false

    if @search_text.gsub(/[ \n\t]/, '').length < 4 then

      @too_short = 4

    else

      show_users = params[:more].nil? || params[:more] == 'users'
      show_shops = params[:more].nil? || params[:more] == 'shops'
      show_countries = params[:more].nil? || params[:more] == 'countries'
      show_spots = params[:more].nil? || params[:more] == 'spots'
      show_posts = params[:more].nil? || params[:more] == 'posts'

      if params[:more].blank? then
        @per_page = 200
        @show_count = true
      end

      @page_num = 1
      if params[:page] then
        @page_num = [1, params[:page].to_i].max
      end

      #Narrow search
      if show_countries
        @countries = Country.search Riddle::Query.escape(@search_text),
                      :without => {:id => 1},
                      :page => @page_num,
                      :per_page => @per_page
      end
      if show_users then
        @users = User.search(Riddle::Query.escape(@search_text),
                      :with => {:is_group => false},
                      :page => @page_num,
                      :per_page => @per_page)
        #@users += User.search :conditions => {:vanity_url => @search_text},
        #              :with => {:is_group => false},
        #              :page => @page_num,
        #              :per_page => @per_page
      end
      if show_spots then
        @spots = Spot.search Riddle::Query.escape(@search_text),
                      :with => {:is_public => true},
                      :without => {:id => 1},
                      :page => @page_num,
                      :per_page => @per_page
      end
      if show_shops  then
        @shops = Shop.search Riddle::Query.escape(@search_text),
                      :with => {:is_public => true},
                      :page => @page_num,
                      :per_page => @per_page
      end

      if show_posts then
        @posts = BlogPost.search Riddle::Query.escape(@search_text),
                      :with => {:published => true},
                      :page => @page_num,
                      :per_page => @per_page
      end

      @users_count = @users.count
      @spots_count = @spots.count
      @shops_count = @shops.count
      @countries_count = @countries.count
      @posts_count = @posts.count

      if params[:more].nil? then
        @users = @users.slice 0..5
        @spots = @spots.slice 0..5
        @shops = @shops.slice 0..5
        @countries = @countries.slice 0..5
        @posts = @posts.slice 0..5
      end
    end

    @search_examples =[]
    if @users_count == 0 && @shops_count == 0 && @spots_count == 0 && @countries_count == 0 then

      random_dive_ids = Media.select_values_sanitized('SELECT dives.id
                          FROM dives, picture_album_pictures
                          WHERE dives.album_id = picture_album_pictures.picture_album_id
                            AND privacy = 0
                          GROUP BY dives.id
                          ORDER BY dives.id DESC
                          LIMIT 1000').sort_by{rand}[0..2]
      random_dives = Dive.find(random_dive_ids)

      random_dive_ids_fish = Media.select_values_sanitized('SELECT dives.id
                              FROM dives, dives_eolcnames
                              WHERE dives.id = dives_eolcnames.dive_id and dives_eolcnames.cname_id is not null
                                AND privacy = 0
                              GROUP BY dives.id
                              ORDER BY dives.id DESC
                              LIMIT 1000').sort_by{rand}[0..2]
      random_dives_fish = Dive.find(random_dive_ids_fish)

      random_dive_ids_club = Media.select_values_sanitized('SELECT dives.id FROM dives WHERE shop_id is not null and privacy = 0 order by dives.id desc').sort_by{rand}[0..2]
      random_dives_club = Dive.find(random_dive_ids_club)

      @search_examples.push random_dives[0].spot.name unless random_dives[0].spot.nil?
      @search_examples.push random_dives[1].user.nickname unless random_dives[1].user.nil?
      @search_examples.push random_dives[2].spot.country.cname unless random_dives[2].spot.nil? || random_dives[2].spot.country.nil?
      #@search_examples.push random_dives_fish[0].eolcnames.first.cname unless random_dives_fish[0].eolcnames.blank?
      @search_examples.push random_dives_club[0].shop.name unless random_dives_club[0].shop.nil?
      @search_examples.push random_dives_club[1].shop.name unless random_dives_club[1].shop.nil?

      @search_examples = @search_examples.flatten.sort_by{rand}
    end

  end

=begin
  def search_any

    spots = Spot.search params[:s]
    locations = Location.search params[:s]
    countries = Country.search params[:s]
    # User.search
    # Fish.search

    dives = spots.map &:dives

    render :json => {
        :success => true,
        :vals => [ spots, locations, countries ].flatten
      }

  end
=end

  def spotredirect
    redirect_to request.fullpath.gsub(/\/pages\/spots\//,"\/explore\/spots\/"), :status=>:moved_permanently
  end


end
