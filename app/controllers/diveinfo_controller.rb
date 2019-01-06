#this class answers to js CRUD queries around unitary dives data

#requires to be able to handle xml data
require 'open-uri'
require 'fileutils'
require 'yaml'
require 'stringex'
require "prawn"
require "prawn/document"
require "prawn/measurement_extensions"

require 'validation_helper'

class DiveinfoController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url  #init the graph connection and everyhting user related


  #def handle_unverified_request
  #  raise ActionController::InvalidAuthenticityToken
  #end

  def sign_dives
    begin
      raise DBArgumentError.new "Missing signature IDs" if params[:sign_ids].blank?
      raise DBArgumentError.new "Could not identify the user/shop signing dives" if @user.nil?
      raise DBArgumentError.new "Don't know if to sign or reject dives" if params[:sign_action].nil?
      ## 0 for REJECT, 1 for SIGN
      raise DBArgumentError.new "Don't know if to sign or reject dives" unless params[:sign_action].to_i == 0 || params[:sign_action].to_i == 1
      raise DBArgumentError.new "Don't know which shop is signing" if params[:shop_id].blank?
      shop = Shop.find(params[:shop_id].to_i)
      raise DBArgumentError.new "User doesn't own shop" unless @user.can_edit?(Shop.find(params[:shop_id].to_i))

      Rails.logger.debug "Signing dives with signatures #{params[:sign_ids].to_json}"

      failed_ids = []
      success_ids = []
      params[:sign_ids].each do |e|
        begin
          s = Signature.find(e.to_i)
          if s.signby != shop
            failed_ids.push e
            next
          end
          if params[:sign_action].to_i == 1
            s.sign
          elsif params[:sign_action].to_i == 0
            s.reject
          end
          Rails.logger.debug "signature #{s.id} processed"
          Notification.create :kind => 'signatureok', :user_id => s.dive.user_id, :about_type => 'Dive', :about_id => s.dive.id if params[:sign_action].to_i == 1
          Notification.create :kind => 'signatureko', :user_id => s.dive.user_id, :about_type => 'Dive', :about_id => s.dive.id if params[:sign_action].to_i == 0


        rescue
          Rails.logger.debug "Could not process signature #{e}: #{$!.message}"
          Rails.logger.debug $!.backtrace
          failed_ids.push e
        end
      end

      render :json => {:success => true, :failed_ids => failed_ids, :success_ids => success_ids}
      return
    rescue
      render api_exception $!, $!.message
      return
    end
  end


  def read_tiny
    begin
      if !params[:picture_id].blank?
        picture_id = params[:picture_id].to_i
        picture = Picture.find(picture_id)
        dive = picture.dive
      else ! params[:dive_id].blank?
        picture_id = nil
        dive_id = params[:dive_id].to_i
        dive = Dive.find(dive_id.to_i)
      end

      if dive.nil? || dive.id == 1 then raise DBArgumentError.new "Incorrect dive" end
      if dive.user.nil? then raise DBArgumentError.new "Orphan dive" end
      if picture_id.nil?
        redirect_to dive.fullpermalink(:canonical)
      else
        redirect_to picture.fullpermalink(:canonical)
      end

    rescue
      Rails.logger.warn "Error forwarding to correct page: #{$!.message}"
      render 'layouts/404.html', :layout => false, :status => 404
      return
    end
  end

  def read_tiny_hash
    begin
      redirect_to (hash_to_object(params[:hash])).fullpermalink(:canonical)
      return
    rescue
      Rails.logger.warn "Error forwarding to correct page: #{$!.message}"
      render 'layouts/404.html', :layout => false, :status => 404
      return
    end
  end

  def read_tiny_home
    vanity = params[:vanity]
    user = User.find_by_vanity_url(vanity)
    if user.nil?
      render 'layouts/404.html', :layout => false, :status => 404
      return
    else
      redirect_to user.fullpermalink(:canonical)
    end
  end

  def create
    #sends out the empty template to be filled in with user data and enabling the creation of a new dive

    begin
      owner = User.find(params[:user_id]) rescue nil
      if owner.nil? then
        raise DBArgumentError.new "Target owner does not exist", owner: params[:user_id]
      end

      dive = Dive.new(
       :spot_id => 1,
       :time_in => "2011-01-01".to_datetime
      )
      dive.user_id = owner.id
      logger.debug "Create new dive for user #{owner.id}"
      dive.privacy = (owner.auto_public)?0:1
      dive.spot_id = 1 #by default we bind it to spot 1 - this prevents potential issues of a dive existing without a spot
      dive.auto_number
      dive.save
      ret = update_dive(dive, params, owner)
      Activity.create(:tag => 'add_dive', :user_id => owner.id, :dive_id => dive.id, :spot_id => dive.spot_id, :location_id => dive.spot.location_id, :country_id => dive.spot.country_id ) rescue logger.warn "Activity not saved for add_dive #{dive.id}"
      render ret
    rescue
      render api_exception $!, 'Could not update dive - 500'
    end
  end


  #PUT method
  # route : match '/:vanity_url/:id/update' => 'diveinfo#update', :vanity_url => /[A-Za-z\.0-9]*/
  def update
    respond_to do |format|
      format.json {
        logger.debug  "someone just asked for a dive update :)"
        #TODO : Check rights !!!! if user's token != our user then render :json => {:success => "false", :error => "no rights"}
        #TODO Check arguments !!!
        #if badly formed -> render :json => {:success => "false", :bad_values=> [arg1, arg2...]}
        #else
        render :json => {:success => "false", :error => "user is not logged in"} if @user.nil?
        begin
          dive = Dive.fromshake(params[:id])
          user = @user
          user = dive.user if dive.user && @user.can_edit?(user)
          render update_dive(dive, params, user)
        rescue
          render api_exception $!, 'Could not update dive - 500'
        end
      }
    end
  end

  def delete
    #deletes a dive
    begin
      if @user.nil?
        render :json => {:success => "false", :error => "user does not exist"}
        return
      end
      dive = Dive.fromshake(params[:id])
      if !@user.can_edit?(dive) then
        render :json => {:success => "false", :error => "you are not allowed to delete that dive"}
        return
      end
      dive.destroy ## do not use DELETE
      #dive.save
      render :json => {:success => "true"}
    rescue
      render api_exception $!
    end
  end


  def computerupload
    #called by the plugin when uploading dives
    #* RETRIEVES
    #* xmlFormSend => UDCF FORMATTED
    #* logFormSend => LOGS USED FOR FURTHER DEBUG IF NEEDED => TO BE STORED IN A TEXT FILE SOMEWHERE FOR FURTHER USE
    #* verFormSend => VERSION OF THE PLUGIN, text string
    #* nbrFormSend => number of dives SENT == number of <DIVE> elements in XML (normally)
    #* nbtFormSend => number of total dives in computer
    #* computer_model => model of computer selected
    #* userid => User's FBID

    respond_to do |format|
      format.json {
      begin
        @udcf = params[:xmlFormSend]
        user = params[:user_id]
        @nbdives = params[:nbrFormSend]
        #@totdives = params[:nbtFormSend]
        #We save the files in the uploads directory
        tmp_log_filename = user+"-"+Time.now.strftime("%Y%m%d%H%M%S")+".log"
        tmp_log = File.new("uploads/"+tmp_log_filename, "w+")
        tmp_log.write params[:logFormSend]
        tmp_log.close()

        uploaded_file = UploadedProfile.new
        uploaded_file.source = "computer"
        uploaded_file.source_detail = params[:computer_model]
        uploaded_file.data = params[:xmlFormSend]
        uploaded_file.log = tmp_log_filename
        uploaded_file.agent = ApiKey.where(key: params[:apikey]).first.comment rescue nil
        uploaded_file.user_id = @user.id rescue nil
        uploaded_file.save
        result = process_export_data(:any, uploaded_file, user)
        result[:success] = true if result[:success] == "true"
        result[:success] = false if result[:success] == "false"
        result[:source] = "computer"
        result[:profile_id] = uploaded_file.id
       render :json => result
      rescue
        render api_exception $!
      end
      }
    end
  end

  def setprivacy
    respond_to do |format|
      format.json {
        dive = Dive.find(params[:dive_id].to_i)
        dive.privacy = params[:privacy].to_i
        dive.save
        render :json => {:success => "true", :privacy => dive.privacy}
      }
    end
  end

  def picasa_share
    ##processes picasa photo links with this format : https://picasaweb.google.com/lh/photo/cBOf4740lcnEztnzqrW6XQ?feat=directlink
    ## process albums : https://picasaweb.google.com/alexksso/T h e N udibranchIsTheBait?authuser=0&feat=directlink
    require 'open-uri'
      if !params[:link].match(/picasaweb.google.com\/lh\//)
        render :json => {:success => false}
      end
      begin
        data = open(params[:link].gsub(/https:\/\//,"http://"))
        url = data.read.match(/<link\ rel='image_src' href="(.+)"\/>/)[1]
        match = url.match(/^(.+)\/[a-zA-Z0-9\_\-]+\/([a-zA-Z0-9\_\-\.\%]+)$/)
        clean_url = match[1]+"/"+match[2]
        render :json => {:success => true, :image => clean_url, :url => params[:link]}
      rescue
        render api_exception $!
      end
  end

  def checkgravatar
    require 'open-uri'
    base = "https://www.gravatar.com/avatar/"
    hash = params[:hash]
    if hash.nil?
      render :json => {:success => false}
      return
    end
    begin
      if Digest::MD5.hexdigest(open("https://www.gravatar.com/avatar/"+hash+".jpg").read) != "d5fe5cbcc31cff5f8ac010db72eb000c"
        render :json => {:success => true, :url => "https://www.gravatar.com/avatar/"+hash+".jpg"}
      else
        render :json => {:success => false}
      end
    rescue
      render :json => {:success => false}
    end
  end

  def get_videothumb
    require 'open-uri'
    if @user.nil?
      render :json => {:success => false, :error => "User must be logged"}
      return
    end

    respond_to do |format|
      format.json {
        jpeg = nil
        filename_url = "user_images/video_"+@user.id.to_s+"-"+Time.now.strftime("%Y%m%d%H%M%S")+".jpg"
        url = params[:url]
        logger.debug "generating thumbnail for "+ ( url||"null" ) + " for user "+@user.id.to_s
        if url.nil?
          render :json => {:success => false, :error => "No URL has been provided"}
          return
        end

        jpeg = Picture.thumb_from_video(url, @user)
        logger.debug "Found thumbnail with url : #{jpeg.to_s}"

        if jpeg.nil?
          render :json => {:success => false, :error => "No media associated with this url"}
          return
        else
          ##get image
          begin
            open("public/"+filename_url, 'wb') do |file|
              file << open(jpeg).read
            end
          rescue
            logger.info "Video thumb has not been loaded from '#{jpeg}' : #{$!.message}"
            logger.debug $!.backtrace.join("\n")
            #note: JS catches that error message
            render :json => {:success => false, :error => "Invalid url"}
            return
          end


          ## add play button
          image = MiniMagick::Image.open("public/"+filename_url)
          ## resize to 640x480
          w, h = image['%w %h'].split
          if w.to_f>h.to_f then
            if w.to_f/6.4>h.to_f/4.8 then
              h = (h.to_f*640/w.to_f).to_i
              w = 640
            else
              w = (w.to_f*480/h.to_f).to_i
              h = 480
            end
          else
            if h.to_f/6.4>w.to_f/4.8 then
              w = (w.to_f*640/h.to_f).to_i
              h = 640
            else
              h = (h.to_f*480/w.to_f).to_i
              w = 480
            end
          end
          image.thumbnail "#{w}x#{h}"

          #result = image.composite(MiniMagick::Image.open("public/img/thumb_play.png"), "jpg") do |c|
          #    c.gravity "center"
          #end
          filename_url_marked = "user_images/video_"+@user.id.to_s+"-"+Time.now.strftime("%Y%m%d%H%M%S")+"_marked.jpg"
          output = "public/"+filename_url_marked
          image.write(output)
          File.chmod(0644, output)
          File.delete("public/"+filename_url) ## remove initial file
          render :json => {:success => true, :thumb => root_url+"#{(filename_url_marked).html_safe}", :video =>params[:url].html_safe}
        end
      }
    end
  end


  def udcfupload
    respond_to do |format|
      format.json {
        begin
          user = params[:user_id]

          ajax_upload = params[:qqfile].is_a?(String)
          filename = ajax_upload  ? params[:qqfile] : params[:qqfile].original_filename
          extension = filename.split('.').last
          # Creating a temp file
          uploaded_profile = UploadedProfile.new
          uploaded_profile.user_id = @user.id rescue nil
          uploaded_profile.source = "file"
          if ajax_upload then
            uploaded_profile.data = request.body.read
          else
            uploaded_profile.data = params[:qqfile].read
          end
            uploaded_profile.log = filename
          uploaded_profile.save
          result = process_export_data(:any, uploaded_profile, user)
          result[:source] = "file"
          render  :json => result, :content_type => "text/html"
          return
        rescue

          #render api_exception $!
          Rails.logger.debug $!.message
          Rails.logger.debug $!.backtrace.join "\n"
          render :json => {:success => false, :user_authentified => !@user.nil?, :error => [$!.message]}
          return
        end
      }
    end
  end

  def divefromtmp
    respond_to do |format|
      format.json {
        errors = []

        if params[:fileid].nil? || params[:fileid].empty?
          render :json => {:success => "false", :msg => "empty fileid"}
          return
        end

        if UploadedProfile.find(params[:fileid].to_i).nil? then
          render :json => {:success => "false", :msg => "invalid fileid"}
          return
        end

        if @user.nil?
          render :json => {:success => "false", :msg => "User not logged"}
          return
        end

        user = @user
        if !params[:user_id].blank? then
          user = User.find(params[:user_id]) rescue nil
        end
        if user.nil? then
          render :json => {:success => "false", :msg => "invalid fileid"}
          return
        end
        if !@user.can_edit?(user) then
          render :json => {:success => "false", :msg => "Cannot create dives on user #{user.id} with user #{@user.id}"}
          return
        end
        Rails.logger.debug "Movescount infos : #{params[:dive_number]} : #{params[:bulk_actions]}"
        ids=[]
        if params[:bulk]=="true"
          bulk_actions_parsed = JSON.parse(params[:bulk_actions])
          bulk_actions_parsed.each do |bap|
            ids.push bap["id"]
          end
        else 
            ids.push params[:dive_number]
            Rails.logger.debug "Movescount pushed ids : #{ids}"
        end
        Rails.logger.debug "Movescount ids : #{ids}"

        export = Divelog.new
        export.from_uploaded_profiles(params[:fileid], ids)

        if !params[:selected_dives].blank?
          begin
            @selected_dives = params[:selected_dives].split(",").map{|i| i.to_i}
          rescue
            @selected_dives = []
          end
        else
          @selected_dives = []
        end

        if params[:bulk] == "true"
          logger.debug "We're here to bulk create new dives"

          action_list = JSON.parse(params[:bulk_actions])
          Dive.transaction do
            action_list.each { |action|
              begin
                case action["action"]
                  when "new_dive"
                    logger.debug "new dive for "+action.to_json
                    dive_id = action["id"].to_i

                    dive = export.dives[dive_id.to_i]
                    if dive.nil? then next end
                    new_dive = Dive.new(
                      :user_id => user.id,
                      :time_in => dive["beginning"].strftime("%Y-%m-%d %H:%M:%S"),
                      :maxdepth => (dive["maximum_depth"]||0.0),
                      :duration => (dive["duration"]||0.0)/60,
                      :privacy => (user.auto_public)?0:1,
                      :uploaded_profile_id => params[:fileid].to_i,
                      :uploaded_profile_index => dive_id.to_i,
                      :spot_id => 1
                    )
                    new_dive.auto_number

                    if new_dive.spot_id.nil?
                      new_dive.spot_id = 1 #assign default blank spot if none found
                    end

                    if !dive["min_water_temp"].nil? then
                      new_dive.temp_bottom = dive["min_water_temp"]
                    end

                    if !dive["max_water_temp"].nil? then
                      new_dive.temp_surface = dive["max_water_temp"]
                    end

                    if !dive["air_temperature"].nil? then
                      new_dive.temp_surface = dive["air_temperature"]
                    end

                    if !dive["dive_comments"].nil? then
                      new_dive.notes = dive["dive_comments"]
                    end

                    if !dive["number"].nil? then
                      new_dive.number = dive["number"].to_i
                    end

                    if !dive["guide"].nil? then
                      new_dive.guide = dive["guide"]
                    end

                    new_dive.save

                    ##Adding dive["buddies"], dive["shop"], dive["divemaster"]
                    if !dive["buddies"].blank? then
                      new_dive.buddies = dive["buddies"]
                    end
                    if !dive["shop"].blank? then
                      new_dive.diveshop = dive["shop"]
                    end
                    # Adding the default gear
                    (user.user_gears.reject{|g| g.auto_feature != 'featured'}).each do |user_gear|
                      l = DiveUsingUserGear.new
                      l.user_gear_id = user_gear.id
                      l.dive_id = new_dive.id
                      l.featured = true
                      l.save
                    end

                    (user.user_gears.reject{|g| g.auto_feature != 'other'}).each do |user_gear|
                      l = DiveUsingUserGear.new
                      l.user_gear_id = user_gear.id
                      l.dive_id = new_dive.id
                      l.featured = false
                      l.save
                    end

                    new_dive.save
                    export.toDiveDB(dive_id.to_i, new_dive) unless begin dive["sample"].count <= 1 rescue false end

                    Activity.create(:tag => 'add_dive', :user_id => user.id, :dive_id => new_dive.id, :spot_id => new_dive.spot_id, :location_id => new_dive.spot.location_id, :country_id => new_dive.spot.country_id ) rescue logger.warn "Activity not saved for add_dive #{new_dive.id}"


                  when "do_nothing"
                    if user.skip_import_dives.nil?
                      user.skip_import_dives = action['digest']
                    else
                      user.skip_import_dives = user.skip_import_dives + ",#{action['digest']}" # add new digest to action list
                    end
                    user.save

                  when "append_to_dive"
                    target_dive = Dive.fromshake(action["dive_id"])
                    dive_id = action["id"].to_i
                    dive = export.dives[dive_id.to_i]

                    logger.debug "Appending profile to dive #{target_dive.id}"
                    target_dive.uploaded_profile_id = nil
                    target_dive.uploaded_profile_index = nil
                    target_dive.save
                    target_dive.reload
                    export.toDiveDB(dive_id.to_i, target_dive)
                    target_dive.uploaded_profile_id = params[:fileid].to_i
                    target_dive.uploaded_profile_index = dive_id
                    target_dive.maxdepth = dive["maximum_depth"] unless dive["maximum_depth"].blank?
                    target_dive.duration = dive["duration"]/60 unless dive["duration"].blank?
                    target_dive.save
                end
              rescue
                logger.debug "ERROR "+$!.message
                logger.debug $!.backtrace.join "\n"
                errors.push(action)
              end

            }
          end

          render :json => {:success => "true", :errors => errors}
          return
        else
          dive = export.dives[params[:dive_number].to_i]
          render :json => {:success => "true", :divedata => export.dive_to_UDCF(dive) }
          return
        end
      }
    end

  end


  def wizard
    respond_to do |format|
      format.js{
        @dive = Dive.find(params[:dive_id])
        @owner = User.find_by_vanity_url(params[:vanity_url])
        @divenumber = params[:dive_id]
      }
    end
  end

  def new
    @pagename = "ADD DIVE"
    @ga_page_category = 'logbook_own_new'

    if @user.nil?
      logger.debug "User is not logged"
      render 'layouts/404', :layout => false
      return
    end
    @owner = User.find_by_vanity_url(params[:vanity_url])
    if !@user.can_edit?(@owner)
      logger.debug "User is not the owner of this vanity url"
      render 'layouts/404', :layout => false
      return
    end
    if @owner.nil? then
      logger.debug "Not such vanity url..."
      render 'layouts/404', :layout => false
      return
    end
    logger.debug "Creating new Dive"
    @dive = Dive.new(:user_id => @owner.id, :shop_id => @owner.shop_proxy_id)
    @dive.auto_number
    render :layout => false, :partial => 'newdive'
  end

  def bulk_page
    @pagename = "DIVE MANAGER"
    @ga_page_category = 'logbook_own_bulk'

    if !params[:selected_dives].blank?
      begin
        @selected_dives = params[:selected_dives].split(",").map{|i| i.to_i}
      rescue
        @selected_dives = []
      end
    else
      @selected_dives = []
    end

    if @user.nil?
      logger.debug "User is not logged"
      render 'layouts/404', :layout => false
      return
    end
    @owner = User.find_by_vanity_url(params[:vanity_url])
    if !@user.can_edit?(@owner)
      logger.debug "User is not the owner of this vanity url"
      render 'layouts/404', :layout => false
      return
    end
    if @owner.nil? then
      logger.debug "Not such vanity url..."
      render 'layouts/404', :layout => false
      return
    end
    #Todo : check rights !
    @dive = Dive.new(:user_id => @owner.id)
    @dive.auto_number
    render :layout => false, :partial => 'bulk_page'
  end

  def bulk_listing
    if @user.nil?
      logger.debug "User is not logged"
      render 'layouts/404', :layout => false
      return
    end

    @owner = User.find(params[:owner_id]) rescue nil
    if @owner.nil?
      logger.warn "Owner #{params[:owner_id]} not found"
      render 'layouts/404', :layout => false
      return
    end

    if !params[:selected_dives].blank?
      begin
        @selected_dives = params[:selected_dives].split(",").map{|i| i.to_i}
      rescue
        @selected_dives = []
      end
    else
      @selected_dives = []
    end

    @dive = Dive.find(1)
    render :layout => false, :partial => 'bulk_listing'
  end

  def put_logs()
    logger.debug "Getting logs to send"
    LogMailer.send_logs(params).deliver
    render :json => {:success => "true"}
  end


  def read
    #sends out the dom of a single dive
    #check if called from web (and not trhough jQuery) redirect to logbook#show of user :vanity_url pointing on the dive :id
    @pagename = "LOGBOOK"
    @ga_custom_analytics = true
    #prepare variables for js
    @owner = User.find_by_vanity_url(params[:vanity_url])
    #make a proper nice page telling the user does not exist
    if @owner.nil? then
      logger.debug "Not such vanity url..."
      render 'layouts/404', :layout => false
      return
    end

   setdive(params[:dive].to_i)
  begin
    Rails.logger.debug "Dive #{params[:dive].to_i} ##{@divenumber} - owner:#{@owner.id}  - user:#{@user.id} - can_edit?: #{@user.can_edit?(@owner)}"
  rescue
    Rails.logger.debug "Dive #{params[:dive].to_i} ##{@divenumber} - owner:#{@owner.id}  - no @user"
  end

   if @divenumber == 0 then
     render :partial => 'diveinfo/nodive'
   elsif @divenumber == 1 and (session[:private] == false || !@user.can_edit?(@owner)) then
     session[:errormsg] = "This Logbook does not belong to you"
     render :partial => 'diveinfo/nodive'
   elsif @divenumber == 1 and @user.can_edit?(@owner)
     render :partial => 'diveinfo/newdive'
   else
     render :partial => 'diveinfo/divepage'
   end

  end

  def update_privacy_dives
    begin

      if params[:listDives].nil? || params[:privacy].nil? || params[:privacy].to_i > 1 || params[:privacy].to_i < 0 then
        render :json => {'success' => false, 'error' => ['invalid parameters']}
        return
      end

      if @user == nil then
        render :json => {'success' => false, 'error' => ['invalid user']}
        return
      end

      dives = params[:listDives].map(&:to_i)
      privacy = params[:privacy].to_i
      updated_dives = []
      not_updated_dives = []
      dives.each do |dive_id|
        dive = Dive.find(dive_id)
        if @user.can_edit?(dive) then
          begin
            dive.privacy = privacy
            dive.save
            updated_dives.push dive_id
          rescue
            not_updated_dives.push dive_id
          end
        else
          not_updated_dives.push dive_id
        end
      end

      render :json => {'success' => true, 'updated' => updated_dives, 'privacy' => privacy, 'not_updated' => not_updated_dives}
    rescue
      render api_exception $!
    end
  end

  def fb_pushtimeline
    begin

      if params[:listDives].nil? || params[:fbtoken].nil? then
        render :json => {'success' => false, 'error' => ['invalid parameters']}
        return
      end

      if @user.nil? then
        render :json => {'success' => false, 'error' => ['invalid user']}
        return
      end


      token = params[:fbtoken]
      if @user.fbtoken != token && !token.nil?
        logger.debug "Updating the user's token with the token from the js page to push on timeline"
        @user.fbtoken = token
        @user.save
      end

      dives = params[:listDives].map(&:to_i)
      updated_dives = []
      not_updated_dives = []

      dives.each do |dive_id|
        begin
          dive = Dive.find(dive_id)
          if !@user.can_edit?(dive)
            raise DBArgumentError.new "dive does not belong to #{@user}"
          end
          dive.publish_to_timeline
          updated_dives.push dive_id
        rescue
          ## since it's now handled asynchronously it can't happen anymore
          not_updated_dives.push dive_id
        end
      end

      render :json => {'success' => true, 'updated' => updated_dives, 'not_updated' => not_updated_dives}
      return
    rescue
      render api_exception $!
      return
    end

  end



  def delete_dives
  begin
    if params[:listDives].nil? then
      render :json => {'success' => false, 'error' => 'invalid parameters'}
      return
    end

    if @user == nil then
      render :json => {'success' => false, 'error' => 'invalid user'}
      return
    end

    dives = params[:listDives].map(&:to_i)
    updated_dives = []

    dives.each do |dive_id|
      dive = Dive.find(dive_id)
      if @user.can_edit?(dive) then
        begin
          Dive.destroy(dive_id)
          updated_dives.push dive_id
        rescue
        end
      end
    end

    render :json => {'success' => true, 'updated' => updated_dives}

  rescue
    render api_exception $!
  end
  end

  def print_dives
    begin
      if params[:listDives].nil? && params["dive"].nil? && params[:hash].nil? then
        render :json => {'error' => 'invalid parameters'}
        return
      end
      if @user == nil then
        render :json => {'error' => 'invalid user'}
        return
      end
      if params[:hash].nil?
        begin
          if !params["dive"].nil?
            dives = [params["dive"].to_i]
          end
          if !params[:listDives].nil?
            dives = params[:listDives].map(&:to_i)
          end
          attributes = {}
          ##define preferences - distances in mm !!
          attributes[:page_width] = 140.mm
          attributes[:page_height] = 203.mm
          attributes[:cut_margins] = 10.mm
          attributes[:hole_offset] = 17.mm
          attributes[:nohole_offset] = 7.mm
          if params["size"] == "a5-1"
            attributes[:reverse] = false
          else
            attributes[:reverse] = true ## recto-verso or not
          end
          attributes[:pictures_pages] = begin params["pictures"].to_i || 0 rescue 0 end
            ## -1 : no limit, 0, no pictures, 1: 1 page (even partial)...)

          #dives.reject! do |dive| !@user.can_edit?(dive) end
          d = Diveprinter.new
          d.generate_pdf_dives dives, @user.id, attributes
          #generate_pdf_dives dives, file, @user.id
          render :json => {
            :success => true,
            :contact_email => @user.contact_email
          }
          return
        rescue
          logger.debug "generation Failed"
          logger.debug $!.message
          render :json => {:success => false, :error => $!}
          return
        end
        #send_file file.path, :filename => "logbook.pdf", :type => "application/pdf"

      else
        begin
          filepath = "/tmp/logbook"+params[:hash]+".pdf"
          send_file filepath, :filename => "logbook.pdf", :type => "application/pdf"
        rescue
          render 'layouts/404', :layout => false
          return
        end
        #File.delete(filepath)
      end
    rescue
      render api_exception $!
    end
  end



  def export_dives
    begin
      logger.debug "parameter received : #{params[:listDives]}"
      if params[:listDives].nil? || params[:listDives].split(",").count == 0 then
        return
      end

      #Make sure that only dives from the owner are requested
      params[:listDives].split(",").each {|id|
        if @user.nil? then
          logger.warn "A non logged in person tried to export a dive (#{id})"
          render :text => "You must be logged in to export a dive"
          return
        elsif Dive.find(id).nil? || !@user.can_edit?(Dive.find(id)) then
          logger.warn "Someone (#{@user.id}) tried to export a dive (#{id}) that he doesn't own"
          render :text => "Are you joking ? You must own the dive to export it !"
          return
        end
      }

      d = Divelog.new
      d.fromDiveDB(params[:listDives].split(","))
      logger.debug "Number of dives read : #{d.dives.count}"

      respond_to do |format|
        format.zxl { render :text => d.toZXL }
        format.udcf { render :text => d.toUDCF(true) }
      end

    rescue DBException => e
      logger.warn "Error while trying to export a dive : #{e}"
      render :text => It.it("You must be logged in and own the dive to export it", scope: 'diveinfo_controller')
    end
  end



  def profilefromtmp
    if params[:file].nil? || params[:file].to_i == 0 || params[:index].nil? then
      render text => ''
      return
    end

    profile_yml = YAML.load_file "#{Rails.root}/config/profile_generation.yml"
    @graph_attributes = profile_yml["default"]
    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    @graph_attributes.merge!(profile_yml[params[:g]], &merger) if !params[:g].nil? && !profile_yml[params[:g]].nil?

    logger.debug "YAML Loaded #{Time.now.to_f}"

    if params[:u] == 'i' then
      @unit = 'imperial'
    else
      @unit = 'metric'
    end
    Rails.logger.debug "DEBUGGING #{params[:file].to_i} and #{params[:index].to_i}"
    @log = Divelog.new
    @log.from_uploaded_profiles(params[:file].to_i, [params[:index].to_i])
    @log.dives = [ @log.dives[ params[:index].to_i ] ]

    logger.debug "Dive data loaded from DB #{Time.now.to_f}"
    respond_to do |format|
      format.xml { render :template => false, :text => @log.toUDCF}
      format.zxl { render :template => false, :text => @log.toZXL}
      format.svg {
            svg = render 'profile'
            logger.debug "SVG render done #{Time.now.to_f}"
          }
      format.png {
            png_file = Tempfile.new('png_from_svg')
            png_file.close

            svg_file = Tempfile.new('svg_to_png')
            begin
              svg_file.write render_to_string :template => false, :action => 'diveinfo/profile.svg'
              svg_file.close

              system('mogrify', '-format', 'png', '-background', 'none', '-write', png_file.path, "svg:"+svg_file.path)

              if !@graph_attributes["logo"].nil? then
                system('composite', '-gravity', 'center', '-blend', '16,100', "#{Rails.root}/#{@graph_attributes['logo']}", png_file.path, png_file.path)
              end

              send_file png_file.path, {:type => 'image/png', :disposition => 'inline'}
            ensure
              png_file.unlink rescue Rails.logger.warn $!.message
              svg_file.unlink rescue Rails.logger.warn $!.message
            end
          }
    end

  end

  def profile

    logger.debug "Beginning profile #{Time.now.to_f}"
    cacheTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
    logger.debug "request from #{request.remote_ip} to #{request.remote_ip} --- cache time=#{cacheTime}"

    begin
      @dive = Dive.fromshake(params[:id])
    rescue
      Rails.logger.warn "Error finding dive on profile: #{$!.message}"
      render nothing: true, :status => 404
      return
    end

    # if the client already has the profile and it's still valid, don't bother about anything else
    if params[:nocache] != "1" and cacheTime and @dive.updated_at <= cacheTime then
      return render :nothing => true, :status => 304
      return
    end

    # Enforces some privacy rules
    ## we need to be able to get private profile on unauthenticated call coming from the server to print dives
    if request.remote_ip.to_s != request.remote_ip && (@dive.nil? || (@user.nil? && @dive.privacy != 0) || (!@user.nil? && !@user.can_edit?(@dive) && @dive.privacy != 0 && (@user.admin_rights.nil? || @user.admin_rights < 3))) then
      logger.debug "you're not allowed to see that graph"
      render :text => ''
      return
    end

    logger.debug "Privacy checks done #{Time.now.to_f}"

    # Merging recursively the parameters
    profile_yml = YAML.load_file "#{Rails.root}/config/profile_generation.yml"
    @graph_attributes = profile_yml["default"]
    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    @graph_attributes.merge!(profile_yml[params[:g]], &merger) if !params[:g].nil? && !profile_yml[params[:g]].nil?

    logger.debug "YAML Loaded #{Time.now.to_f}"

    if params[:u] == 'i' then
      @unit = 'imperial'
    else
      @unit = 'metric'
    end

    # Notify the client about the last update so that he can cache it correctly
    response.headers['Last-Modified'] = @dive.updated_at.httpdate
    response.headers["Pragma"] = ""
    response.headers["expires"] = "-1"
    response.headers["Cache-Control"] = "must-revalidate, private"


    cachedFilename = nil
    respond_to do |format|
      format.svg {
        version = "default"
        if !params[:g].nil? && !profile_yml[params[:g]].nil? then
          version = params[:g]
        end

        cachedFilename = "uploads/profiles/#{@dive.id}_#{version}_#{@unit}_#{I18n.locale}.svg"

        if File.exists?(cachedFilename) && params[:nocache] != "1" then
          cachedFile = File.new(cachedFilename, "r")
          if @dive.updated_at.to_f < cachedFile.mtime.to_f then
            content = ""
            cachedFile.each{|l| content += l}
            render :template => false, :text => content
            cachedFile.close
            logger.debug "cache profile rendered #{Time.now.to_f}"
            return
          end
          cachedFile.close
        end
      }
      format.png {
        version = "default"
        if !params[:g].nil? && !profile_yml[params[:g]].nil? then
          version = params[:g]
        end

        cachedFilename = "uploads/profiles/#{@dive.id}_#{version}_#{@unit}_#{I18n.locale}.png"

        begin
          cachedFile = File.new(cachedFilename, "r")
          if @dive.updated_at.to_f < cachedFile.mtime.to_f then
            cachedFile.close
            send_file cachedFile.path, {:type => 'image/png', :disposition => 'inline'}
            logger.debug "cache profile rendered #{Time.now.to_f}"
            return
          end
          cachedFile.close
        rescue Errno::ENOENT => e
          #Do nothing if file does not exists
        end
      }
    end

    logger.debug "Caching check done #{Time.now.to_f}"

    @log = Divelog.new
    @log.fromDiveDB(Dive.idfromshake(params[:id]))

    logger.debug "Dive data loaded from DB #{Time.now.to_f}"

    respond_to do |format|
      format.xml { render :template => false, :text => @log.toUDCF}
      format.zxl { render :template => false, :text => @log.toZXL}
      format.svg {
            svg = render
            logger.debug "SVG render done #{Time.now.to_f}"
            File.delete(cachedFilename) rescue nil
            cachedFile = nil
            begin
              cachedFile = File.new(cachedFilename, "w")
            rescue Errno::ENOENT => e
              dirname = File.dirname(cachedFilename)
              FileUtils.mkdir_p(dirname)
              cachedFile = File.new(cachedFilename, "w")
            end
            cachedFile.write(svg.first)
            cachedFile.close
            logger.debug "cached file saved #{Time.now.to_f}"
          }
      format.png {
          svg_file = Tempfile.new('svg_to_png')
          begin
            svg_file.write render_to_string :template => false, :action => 'diveinfo/profile.svg'
            svg_file.close


            png_file = nil
            begin
              png_file = File.new(cachedFilename, "w")
            rescue Errno::ENOENT => e
              dirname = File.dirname(cachedFilename)
              FileUtils.mkdir_p(dirname)
              png_file = File.new(cachedFilename, "w")
            end
            png_file.close
            ret = system('mogrify', '-format', 'png', '-background', 'none', '-write', png_file.path, "svg:"+svg_file.path)
            raise DBTechnicalError.new "Failed to generate PNG for SVG" unless ret

            if !@graph_attributes["logo"].nil? then
              system('composite', '-gravity', 'center', '-blend', '16,100', "#{Rails.root}/#{@graph_attributes['logo']}", png_file.path, png_file.path)
            end

            send_file png_file.path, {:type => 'image/png', :disposition => 'inline'}
          ensure
            svg_file.unlink rescue Rails.logger.warn $!.message
          end
      }
    end

    logger.debug "end of profile #{Time.now.to_f}"

  end


  def notify_event
    logger.debug "Entered in notify event #{Time.now.to_f}"
    event = nil

    # Checks what to do with the event notified

    if !params[:picture_id].blank?
      page_liked = :picture
    else
      page_liked = :dive
    end
    if !params[:post_id].blank?
      page_liked = :blogpost
    end

    case params[:event]
      when 'google_like'
        event = :glike
      when 'edge.create'
        event = :like
      when 'google_unlike'
        event = :unlike
        render :json => {:success => "true"}
        return
      when 'edge.remove'
        event = :unlike
        render :json => {:success => "true"}
        return
      when 'comment.create'
        event = :comment
      when 'disqus_comment.create'
        event = :comment
        disqus = params[:disqus_message]
      when 'comment.remove'
        event = :uncomment
        render :json => {:success => "true"}
        return
      else
        render :json => {:success => "false", :error => "invalid event : #{params[:event]}"}
        return
    end

    if page_liked == :picture || page_liked == :dive
      if params[:dive_id].nil? || params[:dive_id].to_i == 0 then
        render :json => {:success => "false", :error => "Invalid dive_id no params"}
        return
      end

      dive = Dive.find(params[:dive_id].to_i) rescue nil
      if dive.nil? then
        render :json => {:success => "false", :error => "Invalid dive_id not found"}
        return
      end

      if !params[:picture_id].blank?
         page_liked = :picture
         picture = Picture.find(params[:picture_id].to_i) rescue nil
         if picture.nil? then
           render :json => {:success => "false", :error => "Invalid dive_id for picture"}
           return
         end
      else
       page_liked = :dive
      end
    elsif page_liked == :blogpost
      if params[:post_id].nil? || (post = begin BlogPost.fromshake(params[:post_id]) rescue nil end) == nil
        render :json => {:success => "false", :error => "Invalid post_id"}
        return
      end
    end
    logger.debug "Notification received for a #{page_liked.to_s}"

    if page_liked == :dive
      if event == :like then
        Notification.create :kind => 'like_dive', :user_id => dive.user_id, :about => dive
      elsif event == :glike
        Notification.create :kind => 'like_dive', :user_id => dive.user_id, :about => dive, :param => 'google_plus'
      elsif event == :comment then
        begin
          # dive.update_fb_comments
          dive.update_disqus_comments disqus
        rescue
          Rails.logger.debug "Failed to update comments on Dive #{dive.id} : #{$!.message}"
          Rails.logger.debug $!.backtrace.join("\n")
        end
        Notification.create :kind => 'comment_dive', :user_id => dive.user_id, :about => dive
      end


    elsif page_liked == :picture
      if event == :like then
        Notification.create :kind => 'like_picture', :user_id => picture.user_id, :about => picture
      elsif event == :glike
        Notification.create :kind => 'like_picture', :user_id => picture.user_id, :about => picture, :param => 'google_plus'
      elsif event == :comment then
        begin
          picture.update_fb_comments
        rescue
          Rails.logger.debug "Failed to update fb_comments on Picture #{picture.id} : #{$!.message}"
          Rails.logger.debug $!.backtrace.join("\n")
        end
        Notification.create :kind => 'comment_picture', :user_id => picture.user_id, :about => picture
      end

    elsif page_liked == :blogpost
      if event == :like then
        Notification.create :kind => 'like_blogpost', :user_id => post.user_id, :about => post
      elsif event == :glike
        Notification.create :kind => 'like_blogpost', :user_id => post.user_id, :about => post, :param => 'google_plus'
      elsif event == :comment then
        begin
          # post.update_fb_comments
          post.update_disqus_comments disqus
        rescue
          Rails.logger.debug "Failed to update fb_comments on BlogPost #{post.id} : #{$!.message}"
          Rails.logger.debug $!.backtrace.join("\n")
        end
        Notification.create :kind => 'comment_blogpost', :user_id => post.user_id, :about => post
      end
    end

    render :json => {:success => "true"}

  end

  ##generic method to updae a dive
  def update_dive(dive, params, user)

    update_errors = []
    needs_lint = false
    raise DBArgumentError.new "User not logged in" if user.nil?
    raise DBArgumentError.new "No dive to update" if dive.nil?
    raise DBArgumentError.new "insufficient rights" if dive.user_id != user.id


    begin
      logger.debug "Date entered : #{params[:date]} #{params[:time_in_hrs]}:#{params[:time_in_mins]}:00"
      dive.time_in = "#{params[:date]} #{params[:time_in_hrs]}:#{params[:time_in_mins]}:00".to_datetime
    rescue
      dive.time_in = DateTime.now if (dive.time_in.nil? || dive.time_in == "2011-01-01 00:00:00".to_datetime)
      e = api_exception $!
      update_errors.push 'Date and time of the dive were badly formatted - could not update'
    end
    dive.duration = params[:duration].to_i


    begin
      if params[:surface_interval].nil? || params[:surface_interval] == ""
        dive.surface_interval = nil
      else
        dive.surface_interval = params[:surface_interval].to_i 
      end
    rescue
      e = api_exception $!
      update_errors.push 'surface interval was badly formatted - could not update'
    end

    previous_tanks = Tank.where(:dive_id => dive.id).to_ary rescue []

    begin
      if params[:update_profile] == "delete" then
        ProfileData.delete_all(:dive_id => dive.id)
        dive.uploaded_profile_id = nil
        dive.uploaded_profile_index = nil
        dive.touch
      elsif params[:update_profile] == "update" && !params[:fileid].nil? && ! params[:diveid].nil? then
        log = Divelog.new
        log.from_uploaded_profiles(params[:fileid], [params[:diveid].to_i])
        log.toDiveDB(params[:diveid].to_i, dive)
        dive.uploaded_profile_id = params[:fileid].to_i
        dive.uploaded_profile_index =  params[:diveid].to_i
        dive.touch
      end
    rescue
      e = api_exception $!
      update_errors.push 'The dive profile has not been updated'
    end

    begin
      raise DBArgumentError.new "Missing spot", spot_id: params[:spot_id] if (spot = Spot.find(params[:spot_id])).nil?
      if dive.spot_id != params[:spot_id] then needs_lint = true end

      #Check if spot is owned by someone else, make copy (case if user chose a spot awaiting moderation)
      logger.debug "Assigning spot #{spot.id}"

      dive.spot_id = spot.id ##moderation checks are done in the model
    rescue
      e = api_exception $!
      update_errors.push 'The spot has not been updated'
    end

    begin
      if params[:number].blank? || params[:number].to_i == 0
        dive.number = nil
      else
        dive.number= params[:number].to_i
      end
    rescue
      e = api_exception $!
      update_errors.push 'The number has not been updated'
    end

    begin
      old_depth = [dive.maxdepth_value, dive.maxdepth_unit] rescue nil
      dive.maxdepth_value = params[:max_depth_value].to_f
      dive.maxdepth_unit = params[:max_depth_unit]
      new_depth = [dive.maxdepth_value, dive.maxdepth_unit] rescue nil
      needs_lint ||= new_depth != old_depth
    rescue
      e = api_exception $!
      update_errors.push 'The maximum depth has not been updated'
    end

    begin
      dive.safetystops_unit_value = params[:safetystops]
    rescue
      e = api_exception $!
      update_errors.push 'The maximum depth has not been updated'
    end

    begin
       if dive.notes != params[:notes] then needs_lint = true end
      dive.notes = params[:notes]
    rescue
      e = api_exception $!
      update_errors.push 'The maximum depth has not been updated'
    end

    begin
      if params[:surface_temp_value].blank?
        dive.temp_surface = nil
      else
        dive.temp_surface_value = params[:surface_temp_value].to_f
        dive.temp_surface_unit = params[:surface_temp_unit]
      end
      if params[:bottom_temp_value].blank?
        dive.temp_bottom = nil
      else
        dive.temp_bottom_value = params[:bottom_temp_value].to_f
        dive.temp_bottom_unit = params[:bottom_temp_unit]
      end
    rescue
      e = api_exception $!
      update_errors.push 'The temperatures have not been updated'
    end

    begin
      if params[:weights_value].blank? then
        dive.weights = nil
      else
        dive.weights_value = params[:weights_value]
        dive.weights_unit = params[:weights_unit]
      end
    rescue
      e = api_exception $!
      update_errors.push 'The amount of weights used has not been updated'
    end

    begin
      divetypes = params[:divetype] || ""
      divetype_clean =[]
      if divetypes != "" then
        divetypes.each do |divetype|
          divetype_split = divetype.gsub(/\ *,\ */, ",").split(",")
          if divetype_split != []
            divetype_split.each do |divetypedata|
              divetype_clean << divetypedata
            end
          end
        end
      end
      dive.divetype = divetype_clean
    rescue
      e = api_exception $!
      update_errors.push 'The dive type tags have not been updated'
    end


    ######
    ###### UPDATE OTHER DIVES SPOT ON MODERATION
    ######
    begin
      spot_curs = dive.spot
      spot_fwd_stack = [dive.spot_id]
      while !spot_curs.moderate_id.nil? do
        moderate_id = spot_curs.moderate_id
        spot_fwd_stack.push moderate_id
        Dive.where(:user_id => user.id).where(:spot_id => moderate_id).map {|d|
          d.spot_id = dive.spot_id
          d.save
        }
        spot_curs = Spot.find(moderate_id)
      end

      while spot_fwd_stack.count > 0 do
        fwd_spot_id = spot_fwd_stack.pop
        Spot.where(:moderate_id => fwd_spot_id).map {|s| spot_fwd_stack.push s.id}
        Dive.where(:user_id => user.id).where(:spot_id => fwd_spot_id).map {|d|
          d.spot_id = dive.spot_id
          d.save
        }
      end
    rescue
      e = api_exception $!
      # NO error to show the user for that one
    end


    ######
    ######UPDATE SPECIES
    ######
    begin
      dive.eolsnames.delete_all #let's scrap all fishes spotted and add the one submitted
      dive.eolcnames.delete_all #let's scrap all fishes spotted and add the one submitted
      if !params[:fish_list].blank? && !params[:fish_list].split(",").empty?
        params[:fish_list].split(",").each do |fishid|
          logger.debug "Adding species id: #{fishid}"
          if  !(fishnum = fishid.match(/c-([0-9]*)/)).nil?
            dive.eolcnames << Eolcname.find(fishnum[1])
          end
          if  !(fishnum = fishid.match(/s-([0-9]*)/)).nil?
            dive.eolsnames << Eolsname.find(fishnum[1])
          end
        end
      end
    rescue
      e = api_exception $!
      update_errors.push 'The list of fish spotted has not been updated'
    end

     ######
     ######UPDATE PICTURES
     ######
    begin
      all_pictures = []
      previous_pictures = dive.pictures
      JSON.parse(params[:pictures]).each do |picture|
        ## ADD new pictures
         logger.debug "sent picture #{picture['id']} - #{picture["image"]} - #{picture["link"]}"
         path = nil
         picturl = picture["image"].gsub(" ","")
         if picturl.match(/^\//)
           path = "public"+picturl
           picturl = nil
         end

         #trying to find the image
         if !picture['id'].nil? && picture['id'].to_i > 0 then
           pict_search = Picture.where :id => picture['id'].to_i, :user_id => user.id
         end
         if pict_search.blank? then
           pict_search = Picture.where( "href like ? AND user_id = ?", picture["link"], user.id)
         end
         if pict_search.blank?
           logger.debug "No picture found : creating a new entry"
           if !(Picture.check_youtube_url picture["link"].gsub(" ","")).nil?
            newpict = Picture.create_youtube_video :url => picturl, :path=> path, :href => picture["link"].gsub(" ",""), :user_id => user.id
           elsif !(Picture.check_dailymotion_url picture["link"].gsub(" ","")).nil?
             newpict = Picture.create_dailymotion_video :url => picturl, :path=> path, :href => picture["link"].gsub(" ",""), :user_id => user.id
           elsif !(Picture.check_vimeo_url picture["link"].gsub(" ","")).nil?
             newpict = Picture.create_vimeo_video :url => picturl, :path=> path, :href => picture["link"].gsub(" ",""), :user_id => user.id
           elsif !(Picture.check_facebook_url picture["link"].gsub(" ","")).nil?
             newpict = Picture.create_facebook_video :url => picturl, :path=> path, :href => picture["link"].gsub(" ",""), :user_id => user.id
           else
            ## Picture created here are only downloads from Internet -- see picture controller for uploads
            newpict = Picture.create_image :url => picturl, :path=> path, :href => picture["link"].gsub(" ",""), :user_id => user.id
           end


           if !picture['notes'].nil? && picture['notes'] != '' then
             newpict.notes = picture['notes']
             newpict.save!
           end
           all_pictures.push newpict
         else
           logger.debug "Existing picture found : #{pict_search.first.id}"
           if !picture['notes'].nil? && picture['notes'] != '' then
             pict_search.first.notes = picture['notes']
             pict_search.first.save
           end
           all_pictures.push pict_search.first
         end


         if !picture["exif"].blank?
           all_pictures.last.exif = picture["exif"]
         end
         if !picture["tags"].nil? then
           all_pictures.last.eolcnames.delete_all
           all_pictures.last.eolsnames.delete_all
           picture["tags"].each do |fish|
             logger.debug "adding to picture species id:#{fish['id']}"
             if !fish['id'].nil? && fish['id'][0] == 'c' then
               dbfish = Eolcname.find(fish['id'][2..-1].to_i)
               all_pictures.last.eolcnames << dbfish unless dbfish.nil?
             end
             if !fish['id'].nil? && fish['id'][0] == 's' then
               dbfish = Eolsname.find(fish['id'][2..-1].to_i)
               all_pictures.last.eolsnames << dbfish unless dbfish.nil?
             end
           end
         end
      end

      # Checking quotas for this dive and user
      logger.debug all_pictures
      all_pictures.map &:save
      if user.quota_type == 'per_dive' && all_pictures.map(&:size).sum > user.quota_limit then
        # we don't update picture list for this dive
        update_errors.push "The pictures have not been updated : you have reached the allowed quota per dive.\n"

      elsif user.quota_type == 'per_month' && (user.dives.reject{|d| d.id==dive.id}).map(&:pictures).push(all_pictures).flatten.uniq.reject{|p| p.nil? || p.created_at < Time.now-1.month} .map(&:size).sum > user.quota_limit then

        update_errors.push "The pictures have not been updated : you have reached your allowed quota for the month.\n"

      elsif user.quota_type == 'per_user' && (user.dives.reject{|d| d.id==dive.id}).map(&:pictures).push(all_pictures).flatten.uniq.reject{|p| p.nil? || p.created_at < Time.now-1.month} .map(&:size).sum > Rails.application.config.default_storage_per_month && (user.dives.reject{|d| d.id==dive.id}).map(&:pictures).push(all_pictures).flatten.uniq.map(&:size).sum > user.quota_limit then
        # we don't update picture list for this dive
        update_errors.push "The pictures have not been updated : you have reached your allowed quota.\n"
      else
        (all_pictures-dive.pictures).each do |picture|
          Activity.create(:tag => 'add_picture', :user_id => user.id, :dive_id => dive.id, :spot_id => dive.spot_id, :picture_id => picture.id, :location_id => dive.spot.location_id, :country_id => dive.spot.country_id ) rescue logger.warn "Activity not saved for add_picture #{picture.id}"
        end

        dive.pictures = all_pictures
      end

    rescue
      e = api_exception $!
      update_errors.push 'The pictures have not been updated'
    end

    begin
      if previous_pictures.empty? && !dive.pictures.empty? then needs_lint = true end
      if !previous_pictures.empty? && dive.pictures.empty? then needs_lint = true end
      if !previous_pictures.empty? && !dive.pictures.empty? && previous_pictures.first.id != dive.pictures.first.id then needs_lint = true end
    rescue
      logger.debug "not sure if we need to lint this dive"
    end



    ######
    ######UPDATE GEAR
    ######
    begin
      if !params[:gear].nil? && !params[:gear].nil? then
        # Param validation
        filtered_gear = ValidationHelper.validate_and_filter_parameters JSON.parse(params[:gear]), { :class => Array,
                :sub => {
                  :class => Hash,
                  :sub => {
                    'id' => { :class => Fixnum, :presence => false},
                    'class' => { :class => String, :presence => true, :in => ['UserGear', 'DiveGear']},
                    'category' => { :class => String, :in => DiveGear.categories, :presence => true},
                    'manufacturer' => {:class => String, :presence => true},
                    'model' => {:class => String, :presence => true},
                    'featured' => {:class => [TrueClass, FalseClass], :presence => true},
                  }
                }
              }


        # Param validation
        UserGear.transaction do
          dive.dive_gears.map &:delete
          dive.dive_using_user_gears.map &:delete
          filtered_gear.each do |gear|

            # For user_gear, we need to store the link. No user_gear is created at this point
            if gear['class'] == 'UserGear' then
              user_gear = UserGear.where(:id => gear['id'], :user_id => user.id).first
              raise DBArgumentError.new "Impossible to find user_gear with id", gear_id:gear['id'] if user_gear.nil?
              l = DiveUsingUserGear.new
              l.user_gear_id = user_gear.id
              l.dive_id = dive.id
              l.featured = gear['featured']
              l.save

            elsif gear['class'] == 'DiveGear' then
              gear.delete('class');
              obj = DiveGear.new(gear);
              obj.id = gear['id']
              obj.dive_id = dive.id
              obj.save

            else
              raise DBArgumentError.new 'class can only be UserGear or DiveGear'
            end

          end
        end
        #there was a save/reload here
      end
    rescue
      e = api_exception $!
      update_errors.push 'The gear list has not been updated'
    end

    begin
      dive.guide = params[:guide]
    rescue
      e = api_exception $!
      update_errors.push 'The guide name has not been updated'
    end

    begin
      if !params[:shop_id].blank? then
        s = Shop.find(params[:shop_id].to_i)
        dive.shop_id = s.id
      elsif params[:shop_id].blank? && !((shop_info = JSON.parse params[:diveshop])["name"] rescue nil).blank?
        ##we create a private shop
        s = Shop.new
        s.name = shop_info["name"]
        s.web = shop_info["url"]
        s.address = "#{shop_info["country"] || ""} - #{shop_info["town"] || ""}"
        s.private_user_id = user.id
        s.flag_moderate_private_to_public = true
        s.save!
        dive.shop_id = s.id
      end
    rescue
      e = api_exception $!
      update_errors.push 'The diveshop has not been updated'
    end

    begin
      if !params[:diveshop].nil? && params[:diveshop]["request_signature"]
        dive.request_shop_signature
      end
    rescue
      e = api_exception $!
      update_errors.push 'The diveshop signature request'
    end

    begin
      dive.buddies = params[:divebuddy]
    rescue
      e = api_exception $!
      update_errors.push 'The list of dive buddies has not been updated'
    end

    begin
      if params[:altitude] != ""
        dive.altitude = params[:altitude].to_f
      else
        dive.altitude = nil
      end
    rescue
      e = api_exception $!
      update_errors.push 'The altitude has not been updated'
    end

    begin
      if params[:water] == ""
        dive.water = nil
      else
        dive.water = params[:water]
      end
    rescue
      e = api_exception $!
      update_errors.push 'The water type has not been updated'
    end

    begin
      logger.debug "Visibility is "+params[:visibility]
      if params[:visibility] != ""
        dive.visibility = params[:visibility]
      else
        dive.visibility = nil
      end
    rescue
      e = api_exception $!
      update_errors.push 'The visibility has not been updated'
    end

    begin
      if params[:current] != ""
        dive.current = params[:current]
      else
        dive.current = nil
      end
    rescue
      e = api_exception $!
      update_errors.push 'The current strength has not been updated'
    end

    begin
      logger.debug "Trip name is #{params[:trip_name]}"
      if !params[:trip_name].nil? && params[:trip_name] != '' then
        dive.trip_name = params[:trip_name]
      else
        dive.trip_name = nil
      end
    rescue
      e = api_exception $!
      update_errors.push 'The trip name has not been updated'
    end

    logger.debug "list_stars is "+params[:list_stars]
    begin
      dive.dive_reviews=params[:list_stars]
    rescue
      e = api_exception $!
      update_errors.push 'The dive reviews have not been updated'
    end


    begin
      dan_data = JSON.parse(params[:dan_data]) unless params[:dan_data].nil?
      dive.dan_data = dan_data
      user.dan_data = dan_data['diver'] unless dan_data.nil?
      user.save
    rescue
      e = api_exception $!
      update_errors.push 'The DAN form has not been updated'
    end


    ### Manage the params[:tanks]
    begin
      tank_data = JSON.parse(params["tanks"])
      Rails.logger.debug "previous_tanks: #{previous_tanks.inspect} - tank_data: #{tank_data.inspect}"
      if !tank_data.blank? || !previous_tanks.blank? then
        tank_data_id=[]
        tank_data.each do |t|
          if t["tank_id"] != ""
            tank_data_id.push t["tank_id"].to_i
          end
        end
        ##delete dropped tanks (and ensure the tank belongs to the dive)
        Tank.where(:dive_id => dive.id).each do |t|
          if !(tank_data_id.include? t.id) && t.dive_id == dive.id
            t.destroy
          end
        end
        #Create or update tanks
        tank_data.each do |t|
          if t["tank_id"] == ""
            tank = Tank.new
          else
            begin
              tank = Tank.find(t["tank_id"].to_i)
            rescue
              tank = Tank.new
            end
          end
          tank.dive_id = dive.id
          tank.material = t["material"]
          tank.gas_type = t["gas_type"]
          tank.volume = t["volume"].to_f
          tank.p_start = t["p_start"].to_f
          tank.p_end = t["p_end"].to_f
          tank.order = t["order"].to_i
          tank.o2 = t["o2"].to_i
          tank.n2 = t["n2"].to_i
          tank.he = t["he"].to_i
          tank.time_start =  t["time"].to_i
          tank.multitank = t["multitank"].to_i
          tank.save
        end
      end
    rescue
      e = api_exception $!
      update_errors.push 'The tank details have not been updated'
    end


    if params[:send_to_dan] == 'true' then
      begin
        dan_data = params['dan_data']
        dan_data = JSON.parse(dan_data) if dan_data.class == String
        DanFormHelper.send_to_dan(dive, dan_data)
      rescue
        e = api_exception $!
        update_errors.push "The form has NOT been sent to DAN. (#{$!})"
      end
    end


    begin
      dive.save!
      dive.reload # makes sure dive has been updated b4 eventual sharing
    rescue
      return api_exception $!, 'Your updates have not been updated'
    end

    if needs_lint
      logger.debug "DIVE WILL BE LINTED"
      out = dive.fb_lint_me
      logger.debug "DIVE LINTED: "+out.to_s
    end
    if params[:callback].blank?
      rh = {:json => {:success => true, :dive_id => dive.id } }
      rh[:json][:messages] = update_errors if update_errors.count > 0
    else
      rh = {:js => {:success => true, :dive_id => dive.id, :callback => params[:callback]}}
      rh[:js][:messages] = update_errors if update_errors.count > 0
    end

    return rh
  end
end

