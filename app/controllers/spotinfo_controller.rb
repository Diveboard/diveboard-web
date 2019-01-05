class SpotinfoController < ApplicationController

  #before_filter :init_fbconnection #init the graph connection and everyhting user related
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  #require 'rubygems'

  def searchcountry
    respond_to do |format|
      format.json {
        term = params[:q]
        result = Country.where("cname LIKE ? AND id > 1", "%#{term}%")
        resulta = []
        result.each do |r| resulta << r.to_api(:public) end
        resulta.reject! &:nil?
        render :json => resulta
      }
    end
  end

  def searchshop
    respond_to do |format|
      format.json {
        query = []
        term = params[:q] || params[:term]
        query.push "@name #{Riddle::Query.escape term}" unless term.blank?
        query.push "@(country_name,city) #{Riddle::Query.escape params[:l]}" unless params[:l].blank?

        args = {:match_mode => :extended, :per_page => 15}
        if params[:lat] && params[:lng] then
          args[:geo] = [params[:lat].to_f*Math::PI/180, params[:lng].to_f*Math::PI/180]
          args[:order] = 'geodist ASC, weight() DESC'
        end
        result = Shop.search query.join(" & "), args

        resulta = []
        result.each do |r|
          next unless (r.flag_moderate_private_to_public.nil? || (!r.flag_moderate_private_to_public.nil? && !@user.nil? && r.private_user_id == @user.id ) )
          resulta << {
            :name => "#{r.name}",
            :id => r.id,
            :label => "#{r.name} (#{r.web})",
            :value => r.name,
            :web => r.web,
            :home => r.fullpermalink(:locale),
            :relative => r.permalink,
            :country => r.country.name,
            :country_code => r.country.ccode,
            :city => r.city,
            :picture => r.picture,
            :claimed => r.is_claimed?,
            :registrable => !r.is_claimed? || (@user && r.is_private_for?(@user)),
            :private => r.user_proxy.nil? || !r.private_user_id.nil?,
            :has_review => !@user.nil? && !@user.review_for_shop(r).nil?
          }
        end
        render :json => resulta
      }
    end
  end
  def searchuser
    respond_to do |format|
      format.json {
        term = params[:q] || params[:term]
        result = User.search Riddle::Query.escape(term)
        result.reject! {|e| !e.shop_proxy_id.nil?}
        resulta = []
        result.each do |r| resulta << {:name => "#{r.nickname} (#{r.full_name})", :id => r.id, :shaken_id => r.shaken_id, :label => "#{r.nickname} (#{r.full_name})", :value => r.nickname, :web => r.fullpermalink(:locale), :relative => r.permalink, :db_id => r.id, :picture => r.picture_small} end
        render :json => resulta
      }
    end
  end


  def read
  begin
    respond_to do |format|
      format.json {
        s= Spot.includes(:country).includes(:location).where(:id => params[:spotid]).first
        render :json => {:success => true, :spot => {:id => s.id, :shaken_id => s.shaken_id, :name => s.name, :location1 => s.location1, :location2 => s.location2, :location3 => s.location3, :country_code => s.country.ccode, :lat => s.lat, :long => s.long, :zoom => s.zoom, :precise => s.precise}}
      }
      format.html {
      }
    end
  rescue
    render api_exception $!
  end
  end

  def user_dives_on_spot
    ##find my dives on a local spot (used in the maps where pins may be on top one of another)
    begin
      respond_to do |format|
        format.json {
          original_spot = Spot.find(params[:spot_id])
          lat_prec = 1/(10**original_spot.lat.to_s.split(".")[1].length).to_f
          min_lat = original_spot.lat - lat_prec
          max_lat = original_spot.lat + lat_prec
          lat = min_lat..max_lat
          long_prec = 1/(10**original_spot.long.to_s.split(".")[1].length).to_f
          min_long = original_spot.long - long_prec
          max_long = original_spot.long + long_prec
          lng = min_long..max_long
          s= Dive.joins(:spot).where('spots.lat' => lat).where('spots.long' => lng).where('dives.user_id' => params[:owner_id].to_i)
          if @user.nil? || @user.id != params[:owner_id].to_i
            s = s.where('dives.privacy' => 0)
          end
          render :json => {
            :success => true,
            :spot => original_spot.to_api(:public, :caller => @user),
            :dives => s.map{|e| e.to_api(:public, :caller => @user) }
          }
        }
        format.html {
        }
      end
    rescue
      render api_exception $!
    end

  end


  def create
    #We create a new item and bind spot.moderate_id to the original spot_id
    #User submits an update for moderation - which is basically a creation with the field towards the source dive
    respond_to do |format|
      format.json {
        if params[:precise] == "false"
          precise = false
        elsif params[:precise] == "true"
          precise = true
        else
          precise= nil
        end
        begin
          check_spot_data
          spot = Spot.new()

          update_spot_from_params spot
          if !params[:spotid].nil? && params[:spotid] != ""
            ##this spot needs moderation
            ##we need to ensure that the spot we use as base is not itself awaiting moderation
            ##TODO ##

            moderate_id = Spot.idfromshake params[:spotid]
            begin
              ## we need to find the spot's original ID
              original_spot = Spot.find(moderate_id)
              moderate_id = original_spot.moderate_id
            end while !moderate_id.nil?

            spot.moderate_id = original_spot.id
          end
          spot.precise = precise

          ##put on the moderation queue
          spot.flag_moderate_private_to_public = true
          spot.private_user_id = @user.id

          logger.debug spot.inspect
          spot.save

          logger.debug "Rendering spot as json : #{spot.to_json}"
          render :json => {:success => true, :spot => {:id => spot.id, :shaken_id => spot.shaken_id, :name => spot.name, :location1 => spot.location1, :location2 => spot.location2, :location3 => spot.location3, :country_code => spot.country.ccode, :lat => spot.lat, :long => spot.long, :zoom => spot.zoom, :precise => spot.precise}}
          return
        rescue
          render api_exception $!
          #flash[:notice] = "Data NOT SAVED"
          #redirect_to "/admin/spot-edit/"+spot.id.to_s
          #return
        end
      }
      format.html {
      }
    end

  end


end
