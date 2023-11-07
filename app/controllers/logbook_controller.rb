# /user_nickname points to the top level of all private dives of a user
# /user_nickname/1234556677 points to a given dive
# /user_nickname/123456677/pictures points to the gallery
# /user_nickname/123456677/picture/123456 points to a specific picture
# /user_nickname/profile points to the profile
#
#  /user_nickname?dive=xx is used for FB compatibility.... redirect is disallowed so we render the OG tags there
#


class LogbookController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :signup_popup_hidden   #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  layout 'main_layout'

  def read
    @pagename = "LOGBOOK"
    @tab = :info ## by default we want the overview tab
    @custom_analytics = true

    if !params[:selected_dives].blank?
      begin
        @selected_dives = params[:selected_dives].split(",").map{|i| i.to_i}
      rescue
        @selected_dives = []
      end
    else
      @selected_dives = []
    end

    if params[:vanity_url]!= nil then
      @owner = User.find_by_vanity_url(params[:vanity_url])
      if !@owner.nil? && !@owner.shop_proxy_id.nil?
        redirect_to @owner.shop_proxy.permalink, :status => :moved_permanently
        return
      end
    end
    if @owner.nil? then
      #user doesn't exist
      logger.debug "apparently can't find the user with url #{params[:vanity_url]} "
      render 'layouts/404', :layout => false
      return
    end





      ##
      ## BEGIN prepare sidebar
      ##
   logger.debug "reading data for user #{@owner.id}"


        if @owner.dives.count > 0 then
          #since user has dives, let's list where he's been
          @dived_location = @owner.dived_location_list
        else
          @dived_location = ""
        end
        ##
        ## END prepare sidebar
        ##

      if params[:bulk].nil? || params[:bulk] == "computer" || params[:bulk] == "manager" || params[:bulk] == "wizard" || params[:bulk] == "gear" then
        @bulk_requested = params[:bulk]
        if !@bulk_requested.nil? &&  @user.nil?
          signup_popup_force_private
        end
      else
        @bulk_requested = nil
      end


      if  params[:bulk] == "wizard" && !params[:profile_id].nil? && params[:profile_id].match(/^[0-9]+$/)
        begin
          Rails.logger.debug "Trying to post-process computer upload number #{params[:profile_id]}"
          uploaded_file = UploadedProfile.find(params[:profile_id].to_i)
          @import_profile_data = process_export_data(:any, uploaded_file, @user)
          @import_profile_data["source"] = uploaded_file.source
        rescue
          @import_profile_data = false
        end
      end

       logger.debug "content asked is : #{params[:content]}"
       if params[:content] == :home && @owner.shop_proxy.nil? then
        @content = 'user_home'

        @display_community = (@owner == @user || @owner.buddies.count > 0 || @owner.public_shops.count > 0)
        if params[:tab].nil?
          @tab = (@display_community && @owner == @user ) ? :community : :info
        else
          @tab = params[:tab]
        end

        if [:widgets, :wallet].include?(@tab) && @owner != @user
          ## we need to force login
          signup_popup_force_private
        end

       elsif params[:content] == :home && !@owner.shop_proxy.nil? then
         @content = 'shop_home'

       elsif params[:content] == :trip then
         @content = 'trip_view'
         logger.debug "Owner: #{@owner.id} - trip: #{params[:tripid]}"
         @trip = Trip.where(:user_id => @owner.id, :id => params[:tripid]).first
         if @trip.nil? then
           params[:content] = :error404
           @content = 'diveinfo/nodive'
         end

       elsif params[:content] == :bulk || !@bulk_requested.nil? then
         if session[:private] == false || !@user.can_edit?(@owner) then
           session[:errormsg] = "This Logbook does not belong to you"
           params[:content] = :error404
           @content = 'diveinfo/nodive'
         else
           @pagename = "MANAGER"

           @dive = Dive.new
           @dives = @owner.dives.paginate(page: params[:page]||1, per_page: 100)
           @content = 'diveinfo/bulk_page'
         end
       elsif params[:content] == :new_dive then
         if session[:private] == false || !@user.can_edit?(@owner) then
           session[:errormsg] = "This Logbook does not belong to you"
           params[:content] = :error404
           @content = 'diveinfo/nodive'
         else
           @pagename = "NEW DIVE"

           @dive = Dive.new( :user_id => @owner.id, :shop_id => @owner.shop_proxy_id)
           @dive.auto_number
           @content = 'diveinfo/newdive'
         end
       else
         if params[:content] == :picture
           ### picture case
           begin
             @picture = Picture.find(params[:picture_id]);
             raise DBArgumentError.new "This Picture does not belong to any dive" if @picture.dive.nil?
             params[:dive] = @picture.dive.id
             logger.debug "Alles Klar, we can show the picture in the logbook"
             @tab = :pictures ### will show the picture tab
           rescue Exception => e
             ## this is a 404 !
             logger.debug e
             #render 'layouts/404', :layout => false
             params[:content] = :error404
             @content = 'diveinfo/nodive'
             session[:errormsg] = "Sorry there's no such picture for #{@owner.nickname} but feel free to check out his other cool dives and pictures !"
             asked_dive = 0
             return
           end
         end

         if params[:dive] != nil then
            begin
              if (dive_number = params[:dive].to_s.match(/^d([0-9]+)$/))
                logger.debug "Checking out direct dive #{params[:dive]}"
                asked_dive = Dive.where(:user_id => @owner.id).where(:number => dive_number[1].to_i).first.id rescue asked_dive = 0
              else
                asked_dive = Dive.idfromshake params[:dive]
              end
              logger.debug "Requested dive : #{asked_dive}"
              if asked_dive == 1
                dive = nil
              else
                dive = Dive.find(asked_dive)
              end
            rescue
              logger.debug "Epic fail, dive to nil: "+$!.message
              logger.debug $!.backtrace
              dive = nil
            end
            logger.debug "Dive & privacy : dive id: #{dive.id rescue "nil"} - #{dive.nil? || dive.privacy}"
            if dive.nil? || (dive.user.id != @owner.id) || (dive.privacy == 1 && (@user.nil? || !@user.can_edit?(@owner))) then
              logger.debug "Refusing the display of dive #{asked_dive}"
              session[:errormsg] = "Sorry this dive is not available but feel free to check out other dives from #{@owner.nickname}"
              asked_dive = 0
            end
         else
           #Case of logged in user seeing his own page
           if !@user.nil? and @user.can_edit?(@owner) then
              #if user has no dives at all
              if @owner.dives.first.nil? then
                asked_dive = 0
              #if he has at least one full dive
              elsif !@owner.full_dives.first.nil? then
                asked_dive = @owner.full_dives.first.id
              #if he has at least one draft dive
              else
                asked_dive = @owner.dives.first.id
              end
           #"public" display
           else
              if @owner.full_public_dives.first.nil? then
                asked_dive = 0
              else
                asked_dive = @owner.full_public_dives.first.id
              end
           end
         end

         if asked_dive == 0 then
           params[:content] = :error404
           @content = 'diveinfo/nodive'
         elsif asked_dive == 1 then
           @pagename = "NEW DIVE"
           @content = 'diveinfo/newdive'
         else
           @content = 'diveinfo/divepage'
           logger.debug "at the enf of this mess we have default dive id = "+asked_dive.to_s
           setdive(asked_dive)
           logger.debug "Will be loading dive "+@divenumber.to_s
         end
       end

       @fb_appid = FB_APP_ID
       @root_tiny_url = ROOT_TINY_URL
       @gmapskey = GOOGLE_MAPS_API

       logger.debug "content to render is : #{@content}"
       
  end



  def get_form_review
    if params[:vanity_url]!= nil then
      @owner = User.find_by_vanity_url(params[:vanity_url])
    end
    if @owner.nil? then
      #user doesn't exist
      logger.debug "apparently can't find the user with url #{params[:vanity_url]} "
      render :text => "The object to review does not exists"
      return
    end

    if @owner.shop_proxy.nil? then
      logger.warn "Form review called on a user and not on a shop"
      render :text => "The object #{@owner.name} cannot be reviewed"
      return
    end

    render :partial => 'shop_pages/form_review', :layout => false, :locals => {
      :review => (@user && @user.review_for_shop(@owner.shop_proxy)),
      :shop => @owner.shop_proxy
    }

  end



  def update_logbook_settings

    errors = []
    #Only callable if user is logged
    if @user.nil? then
      render :json => {:success => "false", :error => "service available for owner only"}
      logger.warn "logbook#update_logbook_settings called by an unlogged user"
      return
    end

    owner = User.find(params[:owner_id]) rescue nil

    if owner.nil? then
      render :json => {:success => "false", :error => "owner_id must be supplied"}
      logger.warn "logbook#update_logbook_settings called without or with wrong owner_id"
      return
    end

    if !@user.can_edit?(owner) then
      render :json => {:success => "false", :error => "not allowed logbook"}
      logger.warn "logbook#update_logbook_settings unduly called to edit owner #{owner.id} with user #{@user.id}"
      return
    end

    begin
      updated_dives = []
      if !params[:fav_dives].nil? then
        JSON.parse(params[:fav_dives]).each do |id, flag|
          begin
            dive = Dive.find(id.to_i)
            if dive.user_id != owner.id then
              logger.warn "updating a logbook of #{dive.user.id} while being #{@user.id}"
              raise DBArgumentError.new "Dive does not belong to you"
            end
            dive.favorite = (flag == true)
            updated_dives.push dive
          rescue Exception => e
            errors.push "Could not set dive #{id} as favorite: #{e.message}"
          end
        end
      end
    updated_dives.each do |dive|
      dive.save
    end
    rescue
      errors.push "Could not update favorite dives"
    end

    begin
      if !params[:total_ext_dives].nil? then
        logger.debug "Updating user #{owner.id} total ext dives with : #{params[:total_ext_dives]}"
        owner.total_ext_dives = params[:total_ext_dives].to_i
        owner.save
      end
    rescue
      errors.push "Could not update total external dives"
    end

    begin
      if !params[:about].nil? then
        logger.debug "Updating user #{owner.id} about with : #{params[:about]}"
        owner.about = params[:about]
        owner.save
      end
    rescue
      errors.push "Could not update about field"
    end

    begin
      if !params[:nickname].nil? then
        logger.debug "Updating user #{owner.id} nickname with : #{params[:nickname]}"
        owner.nickname = params[:nickname]
        owner.save
      end
    rescue
      errors.push "Could not update nickname"
    end

    begin
      if !params[:city].nil? then
        logger.debug "Updating user #{owner.id} city with : #{params[:city]}"
        owner.city = params[:city]
        owner.save
      end
    rescue
      errors.push "Could not update location"
    end

    begin
      if !params[:location].nil? then
        logger.debug "Updating user #{owner.id} location with : #{params[:location]}"
        owner.location = params[:location]
        owner.save
      end
    rescue
      errors.push "Could not update location"
    end

    begin
      if !params[:lat].nil? then
        logger.debug "Updating user #{owner.id} latitude with : #{params[:lat]}"
        owner.lat = params[:lat].to_f
        owner.save
      end
    rescue
      errors.push "Could not update location's latitude"
    end

    begin
      if !params[:lng].nil? then
        logger.debug "Updating user #{owner.id} longitude with : #{params[:lng]}"
        owner.lng = params[:lng].to_f
        owner.save
      end
    rescue
      errors.push "Could not update location's longitude"
    end

    begin
      if !params[:tagid].nil?
        if params[:tagid].match(/^\ *$/)
          # we need to unset tags
          if !owner.tag.nil?
            owner.tag = nil
            owner.save
          end
        else
          my_tag = Tag.fromshake(params[:tagid])
          if my_tag.user_id.nil?
            owner.tag = my_tag
            owner.save
          else
            if my_tag.user_id != owner.id then raise DBArgumentError.new "Tag already assigned" end
          end
        end
      end
    rescue
      logger.warn "the tag id update failed"+$!.message
      logger.debug $!.backtrace
      errors.push "Could not update user's tag id"
    end

    begin
      if !params[:qualifications].blank? then
        settings = JSON.parse(owner.settings)
        settings["qualifs"] = JSON.parse (params[:qualifications])
        owner.settings = settings
        owner.save
      end
    rescue
      logger.warn "the qualifs update failed"+$!.message
      logger.debug $!.backtrace
      errors.push "Could not update user's qualifications"
    end

    begin
      if params[:selected_pic] == "1"
        logger.debug "Real picture"
        ## thumbnail and save
        if params[:crop_pictname] == nil || params[:crop_pictname] == ""
          raise DBArgumentError.new "Could not process picture"
        end
        image = MiniMagick::Image.open("public/tmp_upload/"+params[:crop_pictname])
        logger.debug "using image "+params[:crop_pictname]
        begin
          logger.debug "cropping " + params[:crop_coords_w]+"x"+params[:crop_coords_w]+"+"+params[:crop_coords_x]+"+"+params[:crop_coords_y]
          image.crop params[:crop_coords_w]+"x"+params[:crop_coords_w]+"+"+params[:crop_coords_x]+"+"+params[:crop_coords_y]
          factor =  ((1000000 / params[:crop_coords_w].to_i)/100).to_f
          logger.debug "resizing " + factor.to_s+"%"
          image.resize factor.to_s+"%"
        rescue
          logger.warn "the cropping failed ... doing it the hard way"+$!.message
          ##convert input.jpg -thumbnail x200 -resize '200x<' -resize 50% -gravity center -crop 100x100+0+0 +repage -format jpg -quality 91 square.jpg
          image.thumbnail 'x200'
          image.resize '200x<'
          image.resize '50%'
          image.gravity 'center'
          image.crop '100x100+0+0'
        end
        #end
        image.format "png"
        avatar_path = "public/user_images/"+@user.id.to_s+".png"
        image.write avatar_path
        owner.pict = true
        new_avatar = Picture.create_image({:path => avatar_path, :user_id => owner.id})
        new_avatar.append_to_album owner.avatars.id
        owner.save
      elsif params[:selected_pic] == "0"
        logger.debug "No Picture"
        owner.pict = false
        owner.save
      end
    rescue
      logger.warn "the picture processing failed"+$!.message
      logger.debug $!.backtrace
      errors.push "Could not update picture"
    end

    render :json => {:success => "true", :errors => errors}
  end

  def cool_logbook
    redirect_to User.random_cool_logbook.permalink
  end

  def activity_feed
    if params[:vanity_url]!= nil then
      @owner = User.find_by_vanity_url(params[:vanity_url])
    end
    logger.debug "own :#{@owner}"
    logger.debug "me: #{@user}"
    if @owner.nil? || @user.nil? || @user.id != @owner.id then
      render :text => nil
      return
    end
    render :partial => 'feeds/activity_feed', :locals => {:user => @user, :no_delay => true}
  end

  def widget
    @ga_page_category = "widget"
    @owner = User.find_by_vanity_url params[:vanity_url]
    if @owner.nil?
      render 'layouts/404', :layout => false
      return
    end
    case params[:content]
      when :profile
        render 'widget_profile', :layout => 'widget_layout'
    end
  end

end
