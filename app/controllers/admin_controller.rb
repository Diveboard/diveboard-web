class AdminController < ApplicationController
  require 'spreadsheet'
  require 'stringio'

  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :set_page_name #init the graph connection and everyhting user related
  layout 'main_layout'
  protect_from_forgery


  def email_test
    @tag="test_email"
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      @type = "dive"
      local_user = User.find(params[:user_id]) || @user rescue @user
      @dive = local_user.dives.last
      @page = @dive
      @recipient = @dive.user

      if params[:type] == "comment"
        @comment_text = "This is a dummy comment for the test notification"
        email = HtmlHelper::Inliner.new((render_to_string 'notify_user/notify_comment', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
      
      elsif params[:type] == "external_user_join"
        begin
          @recipient = ExternalUser.find(params[:id].to_i)
          raise ArgumentError if @recipient.nil? || @recipient.email.nil? || @recipient.users_buddies.first.user.nil?
        rescue
          Rails.logger.debug "Could not find ExternalUser #{params[:id]} or he has no user friends"
          @recipient = ExternalUser.where("user_id is null").group("email").reject {|e| e.email.nil? || e.users_buddies.empty?} .reject{|e| !User.find_by_email(e.email).nil? || !User.find_by_contact_email(e.email).nil?} .first
        end
        Rails.logger.debug "ExternalUser recipient #{@recipient.id} #{@recipient.nickname}"
        @subtitle = "Join your dive buddies on Diveboard"
        @buddy = @recipient.users_buddies.first.user
        @comment_text = "Join your buddy #{@buddy.nickname } on Diveboard"
        email = HtmlHelper::Inliner.new((render_to_string 'onboarding/external_user_join', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
      
      elsif params[:type] == "user_reffer_simple"
        begin
          @recipient = User.find(params[:id].to_i)
          raise ArgumentError if @recipient.nil?
        rescue
          Rails.logger.debug "Could not find lUser #{params[:id]} "
          @recipient = User.find(30)     
        end
        Rails.logger.debug "User recipient #{@recipient.id} #{@recipient.nickname}"
        @subtitle = "Share Diveboard with your scuba friends"
        email = HtmlHelper::Inliner.new((render_to_string 'onboarding/user_reffer_simple', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
        
      elsif params[:type] == "shop_onboarding"
        @recipient = Shop.find(params[:id].to_i)
        @shop = @recipient
        @user = @recipient.user_proxy

        begin
          user_id = "*"
          salt = rand(100000)
          group = @shop.user_proxy
          sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
          @claim = (group.fullpermalink(group)+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
        rescue
          @claim = ""
        end

        if params[:step] == "1"
          @subtitle = "Please confirm your free listing data"
          email = HtmlHelper::Inliner.new((render_to_string 'onboarding/shop_check_info', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
        end

        if params[:step] == "2"
          @subtitle = "Make your fans vouch for you!"
          email = HtmlHelper::Inliner.new((render_to_string 'onboarding/shop_ask_fb_reviews', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
        end

        if params[:step] == "3"
          @subtitle = "Start accepting online bookings for free"
          email = HtmlHelper::Inliner.new((render_to_string 'onboarding/shop_market_online_booking', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
        end



      elsif params[:type] == "shop_daily_action"
        @recipient = Shop.find(params[:id].to_i)
        @shop = @recipient
        @user = @recipient.user_proxy

        @global_inbox = @user.global_inbox
        actions = 0
        @global_inbox.each {|e|
          e[:count].map do |what, nb|
            actions += nb
          end
        }
        @subtitle = "#{actions} new item#{"s" if actions>0} in your Diveboard inbox"
        if params[:format] == "text"
          email = render_to_string 'notify_shop/notify_daily_action.text', :layout => false
        else
          email = HtmlHelper::Inliner.new((render_to_string 'notify_shop/notify_daily_action', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
        end
      elsif params[:type] == "like"
        email = HtmlHelper::Inliner.new((render_to_string 'notify_user/notify_like', :layout => 'email_notify_layout'), true, {}, ['public/styles/newsletter.css']).execute
      elsif params[:type] == "digest"
        email = NotifyUser.digest(local_user, :delay => params[:delay], :force => !params[:force].nil?) rescue email = "<h1>#{$!.message}</h1>#{$!.backtrace.join "<br/>"}"
      else
        email = "available parameters : ?type= (comment, like, shop_daily_action, digest) &id= XXXX &user_id= XXXX"
      end
      #NotifyUser.test_email("alex@diveboard.com", "alex@diveboard.com", "test comment", email, "La version texte").deliver

      if email.is_a?(Mail::Message) &&  email.parts.count > 0 then
        email.parts.each do |part|
          render text: part.body and return if part.content_type.match 'text/html'
        end
      elsif email.is_a?(Mail::Message) then
        render text: email.body
        return
      else
        render text: email
        return
      end
    else
      redirect_to "/404.html"
    end
  end

  def set_page_name
    @pagename = "ADMIN"
    @ga_page_category = "admin"
  end

  def test_wizard
    if params[:token] == "xMNXM4DQ3YCd"
      user = User.find(680251975)
      session[TOKEN] = user.token
      cookies.permanent.signed[TOKEN] = user.token
      redirect_to user.permlink+"/1"
      return
    end
  end

  def dashboard
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      @latest_5_users_created = User.order("created_at DESC").limit(5)
      @latest_5_users_logged = User.order("updated_at DESC").limit(5)
      @latest_5_public_dives = Dive.unscoped.where("spot_id <> 1  AND privacy = 0 AND user_id IS NOT NULL").order("created_at DESC").limit(5)
      @latest_5_dives = Dive.unscoped.where("user_id IS NOT NULL").order("created_at DESC").limit(5)
      @spots_to_moderate = Spot.order("created_at DESC").where("flag_moderate_private_to_public IS TRUE").limit(5)
      @spots_to_moderate_total = Spot.order("created_at DESC").where("flag_moderate_private_to_public IS TRUE").count
    else
      redirect_to "/404.html"
    end
  end

  def users
    respond_to do |format|
      format.html{
        if !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 2  || @user.admin_rights >= 4)
          @user_list=[]
          @search_params = params.slice(:sort, :filter)

          user_parse = User.where(:shop_proxy_id => nil)

          if !params[:filter].blank? then
            user_parse = user_parse.where("nickname like :filter or last_name like :filter or first_name like :filter or email like :filter or vanity_url like :filter", :filter => "%#{params[:filter].gsub(/ +/, '%')}%")
          end

          if !params[:sort].nil? then
            user_parse = user_parse.joins("left join dives on users.id = dives.user_id left join pictures on users.id = pictures.user_id").group("users.id").order(params[:sort].to_s)
          end

          @limit = 50
          if !params[:limit].nil? then
            @limit = params[:limit].to_i
          end
          user_parse = user_parse.limit(@limit)

          @start = 0
          if !params[:start].nil? then
            @start = params[:start].to_i
          end
          user_parse = user_parse.offset(@start)

          user_parse.each do |user|
            user_data = Hash.new
            user_data["id"] = user.id.to_s
            user_data["fb_id"] = user.fb_id.to_s
            user_data["nickname"] = user.nickname
            user_data["nb_dives"] = user.dives.count.to_s
            user_data["nb_pics"] = user.pictures.count.to_s
            user_data["vanity_url"] = user.vanity_url
            user_data["created_at"] = user.created_at.to_s
            user_data["updated_at"] = user.updated_at.to_s
            if user.admin_rights>= 4
              user_data["role"] = "UserSpotAdmin"
            elsif user.admin_rights==2
              user_data["role"] = "Useradmin"
            elsif user.admin_rights ==3
              user_data["role"] = "Spotsadmin"
            else
              user_data["role"] = "User"
            end
            @user_list << user_data
          end
        else
          redirect_to "/404.html"
        end
      }
      format.xls{
        #render :text => blob, :type=>"application/ms-excel"
        send_data(render_users_to_xls(User.all.reject!{|e| !e.accept_newsletter_email? }).read(), :type=>"application/ms-excel", :filename => "name.xls")
        return
      }
      format.csv{
        #render :text => blob, :type=>"application/ms-excel"
        send_data(render_users_to_csv(User.all.reject!{|e| !e.accept_newsletter_email? }).read(), :type=>"text/csv", :filename => "name.csv")
        return
      }
    end
  end

  def user_view
    if  !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 2  || @user.admin_rights >= 4)
      if params[:user].nil?
        ##we view
        @user_data = User.find(params[:user_id])
      else
        ##we edit
      #  Parameters: {"commit"=>"EDIT", "pict"=>"0", "authenticity_token"=>"1d74PRTsMYMCclmp0LtOySYqA3lEEpKokDpZsgqDyPw=", "utf8"=>"✓", "gender"=>"0", "user_id"=>"680251975", "admin_rights"=>"4", "user"=>{"location"=>"blank", "nickname"=>"Alexander Casassovici", "token"=>"126856984043229|85a06b7fad00a4399ec7a550.1-680251975|3vpTDblhMc8TJbYZd3hgHCwpcbQ", "last_name"=>"Casassovici", "vanity_url"=>"alexander.casassovici", "birthday"=>"", "settings"=>"{}", "fb_id"=>"680251975", "first_name"=>"Alexander", "email"=>"alex@ksso.net"}}



        @user_data = User.find(params[:user_id])
        if params[:pict].blank?
          @user_data.pict = nil
        else
          @user_data.pict = (params[:pict].to_i == 1)
        end
        @user_data.location = params[:user]["location"]
        @user_data.nickname = params[:user]["nickname"]
        if params[:user]["last_name"].blank?
          @user_data.last_name = nil
        else
          @user_data.last_name = params[:user]["last_name"]
        end
        if params[:user]["first_name"].blank?
          @user_data.first_name = nil
        else
          @user_data.first_name = params[:user]["first_name"]
        end
        if params[:user]["email"].blank?
          @user_data.email = nil
        else
          @user_data.email = params[:user]["email"]
        end
        if params[:user]["contact_email"].blank?
          @user_data.contact_email = nil
        else
          @user_data.contact_email = params[:user]["contact_email"]
        end
        @user_data.vanity_url = params[:user]["vanity_url"]
        if !@user_data.password.nil? && @user_data.password != params[:user]["password"]
          logger.debug "Pwd change requested"
          @user_data.password = Password::update(params[:user]["password"])
        end
        @user_data.settings = params[:user]["settings"]
        @user_data.admin_rights = params[:admin_rights].to_i
        if params[:plugin_debug] == ""
          @user_data.plugin_debug = nil
        else
          @user_data.plugin_debug = params[:plugin_debug]
        end
        @user_data.save

        #we save and reload

      end
    else
      redirect_to "/404.html"
    end
  end

  def species
    if @user.nil? || @user.admin_rights.nil? || !(@user.admin_rights == 3  || @user.admin_rights >= 4)
      redirect_to "/"
      return
    end
    if !params[:species_id].blank?
      begin
        ##it's the species editor gig :)
        id = params[:species_id].split("-")
        if id[0].downcase =="s"
          @species = Eolsname.find(id[1].to_i)
        elsif id[0].downcase =="c"
          @species = Eolcname.find(id[1].to_i).eolsname
        else
          raise DBArgumentError.new "No Such Species"
        end

        if params[:commit] == "Update"
          if @species.species_groups.keys.include? params[:category_name]
            @species.category = params[:category_name]
            @species.save!
          else
            flash[:notice] = "Unknown category - could not update"
          end
        elsif params[:commit] == "Update+children"
          if @species.species_groups.keys.include? params[:category_name]
            @species.get_all_children.each do |c|
              c.category = params[:category_name]
              c.save!
            end
          else
            flash[:notice] = "Unknown category - could not update"
          end
        end

        render "admin/species_editor"
        return
      rescue
        logger.debug $!.message
        flash[:notice] = $!.message
      end
    elsif !params[:category].blank?
      ##category page
      if params[:page].blank?
        off = 0
        @page = 0
      else
        off = params[:page].to_i*1000
        @page = params[:page].to_i
      end
      @species_count = Eolsname.where("category = '#{params[:category]}' AND taxonrank = 'species'").order("parent_id ASC").count
      @species = Eolsname.where("category = '#{params[:category]}' AND taxonrank = 'species'").order("parent_id ASC").limit(1000).offset(off)
      render "admin/species_categories"
      return
    else
      @selected_species = []
      if !params["species_name"].blank? && params["species_name"].length > 3
        Eolsname.search(params["species_name"]).each{|s| @selected_species.push s}
        ##Eolcname.search(params["species_name"]).map(&:eolsname).each{|s| @selected_species.push s}

        @selected_species = @selected_species.uniq
      end
      render "admin/species"
      return
    end
  end

  def mod_history
    if !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 3  || @user.admin_rights >= 4)
      @page = begin params[:page].to_i || 0 rescue 0 end
      @spot_id = begin params[:spot].to_i || nil rescue nil end
      if @spot_id == 0 then @spot_id = nil end
      @max_page = (ModHistory.all.count()/100.to_f).floor+1
      if @spot_id.nil?
        @list = ModHistory.order("created_at DESC").offset(@page*100).limit(100)
      else
        @list = ModHistory.where(:table => "Spot", :obj_id => @spot_id).order("created_at DESC")
      end
      render "admin/spot_mod_history"
    else
      redirect_to "/"
      return
    end
  end


  def spot_moderate2
    ## advanced version of spot moderation tool with plenty wizzardry involved
    if  @user.nil? || @user.admin_rights.nil? || @user.admin_rights < 3
      flash[:notice] = "you have insufficient admin rights"
      redirect_to "/"
      return
    end

    ## STEP 1 : Do the action asked if any
    if !params[:commit].blank? && params[:commit].match("submit_merge_")
      ## let's commit stuff
      Rails.logger.debug "We'll be moderating spot #{params[:id]} with action #{params[:commit]}"
      begin
        @errors =[]
        if params[:commit] == "submit_merge_public" || params[:commit] == "submit_merge_private"

          original_spot_backup = Spot.find(params[:id].to_i).backup

          arg={
              'name' => params[:location],
              'country_id' => Country.find_by_ccode(params[:country_code]).id
          }
          if !params[:location_id].blank? then
           arg['id'] = params[:location_id].to_i
          end


          moderation_location = Location.create_or_update_from_api(arg, :caller => @user)

          Rails.logger.debug "location done, id => #{moderation_location[:target].id} - errors : #{moderation_location[:error].to_s}"

          @errors.push moderation_location[:error] unless moderation_location[:error].blank?


          if params[:region_id].blank? && params[:region].blank?
            moderation_region = nil
          else
            arg = {
              'name' => params[:region]
            }
            if !params[:region_id].blank? then arg["id"] = params[:region_id].to_i end
            moderation_region = Region.create_or_update_from_api(arg, :caller => @user)
            @errors.push moderation_region[:error] unless moderation_region[:error].blank?
            Rails.logger.debug "region done, id => #{moderation_region[:target].id} - errors : #{moderation_region[:error].to_s}"
          end
          arg = {
            'id' => params[:id].to_i,
            'name' => params[:spot_name],
            'lat' => params[:spot_lat].to_f,
            'long' => params[:spot_long].to_f,
            'zoom' => params[:spot_zoom].to_i,
            'country_id' => Country.find_by_ccode(params[:country_code]).id,
            'location' => {
              'id' => moderation_location[:target].id,
            }
          }
          if !moderation_region.nil?
            arg["region"]={"id" => moderation_region[:target].id}
          end
          moderation_spot = Spot.create_or_update_from_api(arg, :caller => @user)
          @errors.push moderation_spot[:error] unless moderation_spot[:error].blank?
          Rails.logger.debug "spot done, id => #{moderation_spot[:target].id} - errors : #{moderation_spot[:error].to_s}"

          moderated_spot = moderation_spot[:target]
          ModHistory.create(:obj_id => moderated_spot.id, :table => moderated_spot.class.to_s, :operation => MOD_UPDATE, :before => original_spot_backup, :after => moderated_spot.backup)

        end
        ##remove from moderation chain and validate spot
        if params[:commit] == "submit_merge_public"
          Rails.logger.debug "Calling validate_public"
          moderated_spot.validate_public JSON.parse(params[:spots_to_merge]).map {|u| u.to_i}, params[:verified_user_id].to_i ##user is signign for that
          Rails.logger.debug "Validate public done"
        elsif params[:commit] == "submit_merge_private"
          ##ensure no spot is public
          slist = JSON.parse(params[:spots_to_merge]).map {|u| u.to_i}
          user_list = []
          slist.each do |s|
            raise DBArgumentError.new "Cannot merge a public spot into a private spot" if Spot.find(s).flag_moderate_private_to_public.nil?
            Spot.find(s).dives.each do |d|
              user_list.push d.user_id
            end
          end

          moderated_spot.validate_private slist
        end
        params[:spot] = params[:id].to_i ## let's get back here
        flash[:notice] = "Spot processed properly, check that everything is OK and move to next spot from list !"
      rescue
        params[:spot] = params[:id].to_i ## let's get back here
        Rails.logger.error "Spot update failed with "+$!.message
        @errors.push "Spot update failed with "+$!.message
      end
    elsif params[:commit] == "submit_jump"
      moderated_spot = nil
      if !params[:jump_spot_from_list].empty?
        params[:spot] = params[:jump_spot_from_list].to_i #todo <= set the spot to edit
      elsif !params[:jump_spot_from_id].empty?
        params[:spot] = params[:jump_spot_from_id].to_i
      end
    else
      moderated_spot = nil
    end


    ## STEP 2 : Create or updat moderation list

    if params[:spot_moderation_chain].blank?
      Rails.logger.debug "Building a new moderation list"
      spots_to_moderate = Spot.where("flag_moderate_private_to_public is true and created_at < ?", 1.day.ago)

      @moderation_list = []
      spots_to_moderate.each do |u|
        toadd = true
        uchain = u.build_moderation_chain
        uchain.each do |g|
          gs= Spot.find(g)
          if @moderation_list.include? gs.id
            ##avoid duplicates
            toadd = false
            break
          end
          if gs.created_at > 1.day.ago
            ##avoid young mods
            toadd = false
            break
          end
        end
        if toadd
          @moderation_list.push u.id
        end
        if @moderation_list.count >20
          ##20 is enough - or it will take forever :)
          break
        end
      end

    else
      @moderation_list = JSON.parse(params[:moderation_list]).map{|u| u.to_i}
      spots_to_remove = []
      begin
        ##remove merged spots
        spots_to_remove.push JSON.parse(params[:spots_to_merge]).map {|u| u.to_i}
        spots_to_remove.flatten!
      rescue
      end
      begin
        ##remove moderated spot
        spots_to_remove.push moderated_spot.id
        spots_to_remove.flatten!
      rescue
      end

      @moderation_list.reject! {|u|
        spots_to_remove.include? u
      }
    end

    if @moderation_list.blank?
      flash[:notice] = "Nothing to moderate yet - come back later and feel proud for cleaning this mess :)"
      return
    end


    ## STEP 3 : Load new page data

    if params[:spot].blank?
      ## we're not editing a specific spot
      mod_spot = Spot.find(@moderation_list.first)
    else
      ##we want to moderate a specific spot
      begin
        mod_spot = Spot.find(params[:spot].to_i)
      rescue
        flash[:notice] = "No Such spot #{params[:spot]}"
        return
      end
    end

    spot_moderation_chain = mod_spot.build_moderation_chain
    @user_spot = Spot.find(spot_moderation_chain.first)
    @spot_moderation_chain = []
    spot_moderation_chain.each do |s|
      ##build object array
      if s!= @user_spot.id
        @spot_moderation_chain.push Spot.find(s)
      end
    end
    ##TODO build similar spot chain
    spname = @user_spot.name
    spname = spname.gsub(","," ").gsub("-"," ").gsub(/(\ )+/, " ").gsub(/\ [a-zA-Z0-9]{1,3}\ /," ").gsub(" ", " | ")
    @spot_similar_chain = Spot.search(spname, :match_mode => :any).reject!{|u|
      ((u.nil? || spot_moderation_chain.include?(u.id)) || (!u.flag_moderate_private_to_public.nil? && u.private_user_id.nil?) )
    } || []
    @spot_close = Spot.search(:geo => [(@user_spot.lat*0.0174532925).to_f, (@user_spot.long*0.0174532925).to_f], :with => {:geodist => 0.0..500.0}, :order => "geodist ASC, weight() DESC", :per_page => 50, :match_mode => :extended).reject!{|u|
      ((u.nil? || spot_moderation_chain.include?(u.id)) || (!u.flag_moderate_private_to_public.nil? && u.private_user_id.nil?) )
    } || []

    @spot_similar_chain = @spot_similar_chain + @spot_close
    @spot_similar_chain.uniq!
    #@spot_similar_chain=[]



  end


  def location_moderate
    @country_list = Country.where(:country_id != 1)
    @country_list.sort! {|a,b| a.locations.count <=> b.locations.count  }
    @country_list.reverse!
    if params[:commit].nil? && params[:id].nil?

    elsif params[:commit] == "show country" || !params[:id].blank?
      @country = Country.find_by_ccode(params[:id] || params[:moderate_country])
      @location = Location.where(:country_id => @country.id)
      @location.sort! {|a,b| a.name <=> b.name}
    elsif params[:commit] == "search"
      search_term = params[:search_name]
      @location = Location.search search_term
      @location.sort! {|a,b| a.name <=> b.name}
    elsif params[:commit] == "show"
      ids = params[:show_ids].gsub(" ","").split(",").map{|u| u.to_i}
      ids.reject!{|u| u == 0}
      @location = []
      ids.each do |u|
        begin
          @location.push Location.find(u)
        rescue

        end
      end
    elsif params[:commit] == "merge locations"
      errors =[]
      begin
        name = params[:name]
        raise DBArgumentError.new "Name can't be empty" if name.blank?
        ccode = params[:country_code]
        raise DBArgumentError.new "Name can't be empty" if ccode.blank?
        country = Country.find_by_ccode(ccode)
        wiki = params[:wiki_text]
        if wiki.blank? then wiki = nil end
        targets = params[:targets].keys.map{|u| u.to_i}

        ##create a new location
        new_location = Location.create {|c|
          c.name = name
          c.country_id = country.id
          ## TODO handle wiki
        }

        targets.each do |t|
          begin
            t.merge_into new_location.id
          rescue
            errors.push $!.message
          end
        end
        ##remove previous locations and relink

        if !errors.blank?
          raise DBArgumentError.new "Errors caught", errors: errors.to_s
        end
        flash[:notice]= "Locations successfully merged into id: #{new_location.id}"
      rescue
        flash[:notice] = "could not merge locations: "+ $!.message
      end

    end

  end

  def dives
    if  !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 3  || @user.admin_rights >= 4)

      @search_params = params.slice(:search_dive_id, :search_user_id, :search_spot_id, :search_privacy, :search_computer)
      @all_dives = Dive.unscoped.order('id DESC')

      if !params[:search_dive_id].nil? then
        logger.debug "Filtering on dive_id : #{params[:search_dive_id].to_i}"
        @all_dives = @all_dives.where(:id => params[:search_dive_id].to_i)
      end

      if !params[:search_user_id].nil? then
        logger.debug "Filtering on user_id : #{params[:search_user_id].to_i}"
        @all_dives = @all_dives.where(:user_id => params[:search_user_id].to_i)
      end

      if !params[:search_spot_id].nil? then
        logger.debug "Filtering on spot_id : #{params[:search_spot_id].to_i}"
        @all_dives = @all_dives.where(:spot_id => params[:search_spot_id].to_i)
      end

      if !params[:search_privacy].nil? then
        logger.debug "Filtering on privacy : #{params[:search_privacy].to_i}"
        @all_dives = @all_dives.where(:privacy => params[:search_privacy].to_i)
      end

      if !params[:search_computer].nil? then
        logger.debug "Filtering on source_detail : #{params[:search_computer]}"
        @all_dives = @all_dives.joins(:uploaded_profile).where('uploaded_profiles.source' => 'computer', 'uploaded_profiles.source_detail' => params[:search_computer])
      end

      if params[:start].nil? || params[:start].to_i <= 0 then
        @start = 0
      else
        logger.debug "adding offset : #{params[:start].to_i}"
        @start = params[:start].to_i
        @all_dives = @all_dives.offset(@start)
      end

      if params[:limit].nil? || params[:limit].to_i <= 0 then
        @limit = 10
        @all_dives = @all_dives.limit(@limit)
      else
        @limit = params[:limit].to_i
        @all_dives = @all_dives.limit(@limit)
      end


    else
      redirect_to "/"
      return
    end
  end

  def shops_dash
    if  @user.nil? || @user.admin_rights.nil? || !(@user.admin_rights == 3  || @user.admin_rights >= 4)
      redirect_to "/"
      return
    end

  end

  def shops
    if  @user.nil? || @user.admin_rights.nil? || !(@user.admin_rights == 3  || @user.admin_rights >= 4)
      redirect_to "/"
      return
    end

    if params[:id].blank?
      @shop = Shop.new
    else
      begin
        @shop = Shop.find(params[:id].to_i)
      rescue
        @shop = Shop.new
      end
    end

  end

  def shops_save
    if  @user.nil? || @user.admin_rights.nil? || !(@user.admin_rights == 3  || @user.admin_rights >= 4)
      redirect_to "/"
      return
    end
    case params[:commit]
      when "SAVE"
        begin
          ##update data
          if params[:post].blank? || ( !params[:post].blank? &&  params[:post][:id].blank?)
            s = Shop.create(params[:shop])
            flash[:notice] =  "Shop created successfully with id "+s.id.to_s
          else
            s = Shop.update(params[:post][:id].to_i, params[:shop])
            flash[:notice] =  "Shop updated successfully"
          end

          ##update moderation stuff
          if params[:moderation_status].to_sym != self.status
            case params[:moderation_status].to_sym
              when :public
                logger.debug "making shop public"
                s.make_public
              when :private
                logger.debug "making shop private"
                s.make_private
              when :awaiting_moderation
                logger.debug "making shop awaiting moderation"
                if s.flag_moderate_private_to_public != 1
                  #s.make_private
                  s.flag_moderate_private_to_public = 1
                  if s.private_user_id.nil?
                    ## force a wrong user just in order to put it back in moderation state
                    s.private_user_id = 0
                  end
                  s.save
                end
              when :disabled
                logger.debug "making shop disabled"
                s.disable_shop
            end

          end
          #finalize
          s.reload ### if a user has been created we need to reload
          if !s.name.blank? && s.user_proxy.nil? && s.status == :public
            s.create_proxy_user!
          end
          redirect_to "/admin/shops/"+s.id.to_s
          return
        rescue
          flash[:notice] = "Save failed : "+$!.message
          @shop = Shop.new(params[:shop])
          render "admin/shops"
          return
        end
      when "MERGE"
        begin
          from = Shop.find(params[:from].to_i)
          to = Shop.find(params[:to].to_i)
          fromdives = from.dives.map(&:id).to_s
          from.merge_into to.id
          flash[:notice] = "shop #{from.id} has been disabled and dives #{fromdives} have been moved to shop #{to.id}"
          redirect_to "/admin/shops/"+to.id.to_s
          return
        rescue
          flash[:notice] = "Merge failed with error: "+$!.message
          redirect_to "/admin/shops/"+from.id.to_s
          return
        end

      when "BULK_MERGE_SELECTED"
        begin
          current_shop = params[:merge_list][:original].to_i
          @shop = Shop.find(current_shop)
          to =@shop
          shop_list = JSON.parse(params[:merge_list][:id]).map{|i| Shop.find(i.to_i)}
          fail_notice = []
          success_notice = []
          shop_list.each do |from|
            begin
              Rails.logger.debug "merging shop #{from.id} into #{to.id}"
              divescount = from.dives.count
              from.merge_into to.id
              success_notice << {:id=> from.id, :message => "#{divescount} dives moved from #{from.id} to #{to.id}"}
            rescue
              Rails.logger.debug "Merge failed "+$!.message
              fail_notice << {:id => from.id, :message => $!.message}
            end
          end
          if !fail_notice.empty?
            flash[:notice] = "Merge failed for spots "+fail_notice.to_json
          else
            flash[:notice] = "Merge Successful" + success_notice.to_json
          end
          Rails.logger.debug "Merging bulk shops #{shop_list}"
        rescue

        end
        redirect_to "/admin/shops/"+@shop.id.to_s
        return
      when "SEARCH"
        begin
          raise DBArgumentError.new "Nothing to search" if params[:text].blank? && params[:id].blank?
          @search_spot_result = [Shop.find(params[:id].to_i)] unless params[:id].blank?
          @search_spot_result = Shop.search(params[:text]) unless !params[:id].blank?
        rescue
          flash[:notice] = "Merge failed with error: "+$!.message
        end
        render "admin/shops_dash"
        return
      else
          redirect_to "/admin/shops"
          return
      end
  end


  def pictures
    if  !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 3  || @user.admin_rights >= 4)

      @search_params = params.slice(:search_user_id, :search_great_pic)
      @all_pictures = Picture.unscoped.order('id DESC')
      @all_pictures = @all_pictures.joins(:picture_album_pictures => :album).where("albums.kind <> 'wallet'")

      if !params[:search_user_id].nil? then
        logger.debug "Filtering on user_id : #{params[:search_user_id].to_i}"
        @all_pictures = @all_pictures.where(:user_id => params[:search_user_id].to_i)
      end

      if !params[:search_great_pic].nil? then
        flag = params[:search_great_pic] == "true"
        flag = nil if params[:search_great_pic] == "nil"

        logger.debug "Filtering on great_pic : #{flag}"
        @all_pictures = @all_pictures.where(:great_pic => flag)
      end
      if !@all_pictures.blank?
        if params[:start_id].nil? || params[:start_id].to_i <= 0 then
          @start_id = @all_pictures.first.id + 1
        else
          @start_id = params[:start_id].to_i
          logger.debug "adding offset : #{@start_id}"
          @all_pictures = @all_pictures.where("pictures.id < #{@start_id}")
        end

        if params[:limit].nil? || params[:limit].to_i <= 0 then
          @limit = 20
          @all_pictures = @all_pictures.limit(@limit)
        else
          @limit = params[:limit].to_i
          @all_pictures = @all_pictures.limit(@limit)
        end
      end
    else
      redirect_to "/"
      return
    end
  end

  def mark_pictures_great
    if  !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 3  || @user.admin_rights >= 4) then
      errors = []
      ret = {}
      begin
        raise DBArgumentError.new "ids should be given" if params[:ids].blank?
        raise DBArgumentError.new "great_pic flag should be given" if params[:great_pic].nil?
        raise DBArgumentError.new "great_pic should be 'true', 'false' or ''" unless ["true", "false", true, false, ""].include?(params[:great_pic])

        pics = JSON.parse(params[:ids])

        pics.each do |pic_id|
          begin
            pic_id = pic_id.to_i
            pic = Picture.find(pic_id) rescue nil
            raise DBArgumentError.new "unknown pic_id" if pic.nil?

            Rails.logger.debug "pic.great_pic : #{pic.great_pic} - params[:force] : #{params[:force]}"
            if pic.great_pic.nil? || params[:force] == "true" then
              pic.great_pic = params[:great_pic]
              pic.save!

              pic.reload
              Notification.create(:user => pic.user, :kind => 'great_picture', :about => pic) if pic.great_pic
              #pic.publish_to_fb_page if pic.great_pic ## we're pushing to the Diveboard FB page
            end

            pic.reload
            ret[pic_id] = pic.great_pic
          rescue
            logger.warn $!.message
            logger.debug $!.backtrace
            errors.push $!
          end
        end
        render :json => {:success => true, :ret => ret, :errors => errors}
      rescue
        logger.warn $!.message
        logger.debug $!.backtrace
        errors.push $!
        render :json => {:success => false, :errors => errors}
      end
    else
      redirect_to "/"
      return
    end
  end

  def uploaded_profile
    if  !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 3  || @user.admin_rights >= 4)

      send_data(UploadedProfile.find(params[:id]).data, :type => 'application/octet-stream', :filename => "profile", :disposition => 'inline' )

    else
      redirect_to "/"
      return
    end
  end

  def monitoring
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      @running_procs = []
      IO.popen("ps auwwx | grep '#{Rails.application.config.workers_process_name}' | grep -v 'grep'") { |io| while (line = io.gets) do @running_procs.push line.chomp end }
    else
      redirect_to "/404.html"
    end
  end

  def reviews
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      if !params[:id].nil? && !params[:mark_spam].nil? then
        begin
          review = Review.find(params[:id])
          review.spam = params[:mark_spam]
          review.reported_spam = false
          review.flag_moderate = false
          review.save!
          redirect_to "/admin/reviews?what=#{params[:what]}"
          return
        rescue
          logger.debug "ERROR: #{$!.message}"
          flash[:notice] = "ERROR: #{$!.message}"
        end
      end

      if !params[:valid_all].nil? && params[:valid_all] == 'moderate' then
        Review.where(:flag_moderate => true).each do |review|
          begin
            review.spam = false
            review.reported_spam = false
            review.flag_moderate = false
            review.save!
          rescue
            flash[:notice] = "#{flash[:notice]} - #{$!.message}"
          end
        end
      end

      case params[:what]
      when 'spam'
        @list_reviews = Review.where("spam")
      when 'not_spam'
        @list_reviews = Review.where("not spam")
      when 'all'
        @list_reviews = Review.all
      when 'user'
        @list_reviews = Review.where(:user_id => params[:user_id])
      when 'shop'
        @list_reviews = Review.where(:shop_id => params[:shop_id])
      else
        @list_reviews = Review.where("flag_moderate OR reported_spam")
      end

    else
      redirect_to "/404.html"
    end
  end


  def user_kill
    if  !@user.nil? && !@user.admin_rights.nil? && @user.admin_rights >= 4
      @user_data = User.find(params[:user_id])
      @user_data.dives.each do |dive|
        dive.pictures.delete_all
      end
      @user_data.dives.delete_all
      @user_data.delete
      render :text => "User is no more "
      return
    else
      redirect_to "/404.html"
    end
  end

  def testfbusergen
    #params[:perms] sets permissiosn fot test users on application
    ## all = publish_stream,email,publish_checkins,user_photos,user_videos
    #if  !@user.nil? && !@user.admin_rights.nil? && @user.admin_rights >= 4
    @test_users = Koala::Facebook::TestUsers.new(:app_id => FB_APP_ID, :secret => FB_APP_SECRET)
    if params[:perms].nil?
      new_user = @test_users.create(false)
    elsif params[:perms] == "all"
      new_user = @test_users.create(true,"publish_stream,email,publish_checkins,user_photos,user_videos")
    else
      new_user = @test_users.create(true, params[:perms])
    end
    render :text => "<div id='userid'>#{new_user["id"]}</div><div id='loginurl'>#{new_user["login_url"]}</div><div id='password'>#{new_user["password"]}</div><div id='token'>#{new_user["access_token"]||""}</div><div id='email'>#{new_user["email"]}</div>"
    #render :json => new_user
    #else
    #    redirect_to "/404.html"
    #end
  end
  def testfbuserdel
    #http://dev.diveboard.com/admin/testfbuserdel/all deletes all users
    @test_users = Koala::Facebook::TestUsers.new(:app_id => FB_APP_ID, :secret => FB_APP_SECRET)
    if params[:user_id] == "all"
      begin
        @test_users.list.each do |u|
          @test_users.delete(u) rescue Rails.logger.warn $!.message
        end
        render :text => "All users deleted"

      rescue
        render :text => "All users should be deleted (was an exception)"

      end
    else
      begin
        @test_users.delete(params[:user_id])
        render :text => "User deleted"
      rescue
        render :text => "User deleted (was an exception)"
      end

    end
  end
  def testshopgen
    #if  !@user.nil? && !@user.admin_rights.nil? && @user.admin_rights >= 4
    test_shop = Shop.create({
      :source => 'TEST',
      :lat => nil,
      :lng => nil,
      :name => 'Test shop'
    })
    test_shop.create_proxy_user!
    test_shop.reload

    test_shop.name = "#{test_shop.name} #{test_shop.vanity_url.gsub(/[^0-9]/, '')}"
    test_shop.delta = true
    test_shop.save

    if !params[:user_id].nil?
      claim_url = ShopClaimHelper.generate_url_confirm_claim(User.find(params[:user_id]), test_shop.user_proxy) rescue nil
    end

    if !params[:email].blank? then
      test_shop.email = params[:email]
      test_shop.save
    end

    ThinkingSphinx::Deltas::IndexJob.new('shop_core').perform

    render :text => "<div id='shopid'>#{test_shop["id"]}</div><div id='shopurl'>#{test_shop.user_proxy.permalink}</div><div id='shop_user_id'>#{test_shop.user_proxy.id}</div><div id='claim_url'>#{claim_url}</div>"
  end

  def testshopvalid
    shop = Shop.find(params[:shop_id]) rescue nil
    user = @user rescue nil
    user ||= User.find(params[:user_id]) rescue nil
    claim_url = ShopClaimHelper.generate_url_confirm_claim(user, shop.user_proxy, session[:utm_campaign]) rescue nil
    render :text => "<div id='shopid'>#{shop.id}</div><div id='claim_url'>#{claim_url}</div>"
  end


  #This service extracts part of logs based on an IP or user_id. Should be used later in async
  def logf
    if !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 2  || @user.admin_rights >= 4)
      begin
        user_id = nil #params[:user_id]
        user_ip = params[:ip]
        date = params[:date]
        return render :text => 'Error: no date provided' if date.nil?
        return render :text => 'Error: date has wrong format. Should be YYYY-MM-DD' unless date.match /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
        return render :text => 'Error: no user_id or ip provided' if date.nil? || user_ip.nil?

        logpath = Rails.logger.instance_variable_get(:@log).path
        dirname = File.dirname(logpath)
        filename = File.basename(logpath)
        Rails.logger.debug "Scanning files #{filename} in #{dirname}"

        #dirname = '/var/www/alpha.diveboard/current/log'
        #filename = 'production.log'
        #date = '2011-11-12'

        #First, find the log files to parse depending on the date
        logfiles = []
        first_date = '9999-01-01'
        Dir.entries(dirname).reject{|f| !f.match "^#{filename}"} .sort.each do |file|
          last_date = first_date

          #uncompressing log files on the file if needed
          if file.match /\.gz$/ then
            head_cmd = "zcat '#{dirname}/#{file}' | head "
          else
            head_cmd = "head '#{dirname}/#{file}'"
          end

          IO.popen(head_cmd).each do |line|
            m0 = line.match "^([0-9-]*) [0-9.:]* - |Started GET.* at ([0-9-]*) [0-9:]* "
            next unless m0
            first_date = m0[1] || m0[2]
          end

          logfiles.push "#{dirname}/#{file}" if first_date <= date && last_date >= date
        end


        #For each process id follow describes if it should be reported or not
        #  true = identified as to follow
        #  false = identified as not interesting
        #  nil = don't know if we'll need it or not
        follow = {}
        matched_data = ""
        logfiles.sort.reverse.each do |interesting_log|
          File.open(interesting_log, "r").each do |line|
            line.chomp!

            # first filter by date
            m0 = line.match "^#{date} [0-9.:]* - [A-Z]* - #([0-9]*) -"
            next unless m0
            process_id = m0[1]
            m1 = line.match /- INFO - #([0-9]*) -.*Started ([A-Z]*).*"([^"]*)" for ([0-9.]*) /
            #m2 = line.match /- INFO - #([0-9]*) -.*-  User already authentified and exists, id = ([0-9]*), vanity = (.*)/

            follow[process_id] = false if m1 #new request starting
            follow[process_id] = true if user_ip && m1 && m1[4] == user_ip #to follow due to ip
            matched_data += line + "\n" if follow[process_id]
            #puts line if follow[process_id]
          end
        end

        return render :text => matched_data

      rescue
        return render :text => "Exception: #{$!.message}\n#{$!.backtrace.join("\n")}", :content_type => 'text/plain'
      end
    else
      return render :text => "You're no root"
    end
  end


  def blogposts
    if !@user.nil? && !@user.admin_rights.nil? && (@user.admin_rights == 2  || @user.admin_rights >= 4)
      if params[:type].nil? || params[:type] == "moderation"
        @post_list =  BlogPost.where(:flag_moderate_private_to_public => true)
      elsif params[:type] == "perso"
        @post_list =  BlogPost.where("published_at is not NULL").where(:published => false)
      elsif params[:type] == "main"
        @post_list =  BlogPost.where("published_at is not NULL").where(:published => true)
      elsif params[:type] == "all"
        @post_list =  BlogPost.where("published_at is not NULL")
      end
      @post_list = @post_list.order("published_at DESC").paginate(:page => params[:page], :per_page => 10)
      #@post_list = @post_list.reject {|p| p.nil?}

    else
      redirect_to "/404.html"
    end

  end

  def blogposts_moderate
    begin
      raise DBArgumentError.new "You need to have admin rights to do this" if  @user.nil? || ( !@user.nil? && !@user.admin_rights.nil? && ( @user.admin_rights < 3 ))
      success_ids = []
      error_ids = []
      errors = []
      logger.debug "Moderation blog posts "+ (params[:ids].to_s) +" with action "+(params[:action].to_s)
      params[:ids].each do |id|
        begin
          post = BlogPost.fromshake(id)
          if params[:moderate_action] == :approve
            post.flag_moderate_private_to_public = false
            post.published = true
            post.save
            post.reload
            post.publish_to_fb_page if Rails.env == "production"
          elsif params[:moderate_action] == :dismiss
            post.flag_moderate_private_to_public = false
            post.save
          end
          success_ids << id
        rescue
          error_ids << {:id=> id, :error => $!.message, :error_code => $!.error_code}
          errors.push $!.as_json
        end
      end
      render :json => {:success => true, :success_ids => success_ids, :error_ids => error_ids, errors => errors}
    rescue
      errors.push $!
      render :json => {:success=> false, :errors=>errors, :success_ids => [], :error_ids => params[:ids]}
    end
  end


  def newsletter
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      if params['a'] == 'build' then
        render 'newsletter_builder'
        return
      elsif params['a'] == 'delete' then
        letter = Newsletter.find(params['id']) rescue nil
        logger.info letter.to_json
        letter.destroy unless letter.distributed_at
        redirect_to "/admin/newsletter"
        return

      elsif params['a'] == 'generate' then
        content = render_to_string :partial => 'notify_user/newsletter_content', :locals => {
          :user => User.find(48),
          :blogpost => begin BlogPost.find(params['blogpost_id']) rescue nil end,
          :destination => begin Country.find_by_ccode(params['country_code']) rescue nil end,
          :picture_gallery => begin Picture.find(params['picture_gallery_ids']) rescue nil end
        }
        letter = Newsletter.create :html_content => content
        redirect_to "/admin/newsletter?a=edit&id=#{letter.id}"
        return

      elsif params['a'] == 'edit' then
        letter = Newsletter.find(params['id']) rescue nil

        if letter && params['updated_html'] then
          if !params['newsletter_title'].nil? && params['newsletter_title'] != ""
            letter.title = params['newsletter_title']
          else
            letter.title = nil
          end
          letter.html_content = params['updated_html']
          letter.save!
          redirect_to "/admin/newsletter?a=edit&id=#{letter.id}"
          return
        end

        render 'newsletter_editor', :locals => {:letter => letter}
        return

      elsif params['a'] == 'preview' then
        letter = Newsletter.find(params['id']) rescue nil
        user = User.find(params['user_id']) rescue nil
        render 'newsletter_previewer', :locals => {:letter => letter, :user => user}
        return

      elsif params['a'] == 'send_preview' then
        letter = Newsletter.find(params['id']) rescue nil
        user = User.find(params['user_id']) rescue nil

        mail = NotifyUser.newsletter(letter, user, params['email']).deliver
        flash[:notice] = "Newsletter delivered to #{mail.to}"
        redirect_to "/admin/newsletter?a=preview&id=#{letter.id}"
        return
      else
        render :locals => {:letter => letter, :user => user}
      end


    else
      redirect_to "/404.html"
    end
  end
  def newsletter_send
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      begin
        letter = Newsletter.find(params[:id].to_i)
        letter.deliver("shop_proxy_id is null")
        render :json => {:success => true}
      rescue
        render :json => {:success => false, :errors => [$!], :error => $!.message}
      end
    else
      redirect_to "/404.html"
    end

  end

  def charts
    if !@user.nil? &&!@user.admin_rights.nil? && @user.admin_rights > 1
      render
    else
      redirect_to "/404.html"
    end
  end

  def uncluster_spot
    redirect_to "/404.html" and return if @user.nil? || @user.admin_rights.nil? || @user.admin_rights <= 1

    if params[:id] then
      cluster_roots = [params[:id].to_i] rescue []
    else
      cluster_roots = Media.select_all_sanitized('SELECT cluster_id, count(distinct spots.id) cnt
        FROM spot_compare, spots
        WHERE spots.id = spot_compare.a_id
        AND cluster_id is not null AND a_id not in (select a_id from spot_moderations where b_id is null)
        AND not(spots.flag_moderate_private_to_public is false and spots.private_user_id is null)
        group by cluster_id
        HAVING cnt > 1
        ORDER BY CNT DESC')
      if params[:next] && cluster_roots.count > 0 then
        redirect_to "/admin/uncluster_spot/#{cluster_roots.first['cluster_id']}"
        return
      else
        render 'uncluster_roots', :locals => {:roots => cluster_roots}
        return
      end
    end

    #getting loosely linked clusters
    cluster_links = {}
    links_data = Media.select_all_sanitized('select distinct c.cluster_id cluster_id1, b_c.cluster_id cluster_id2
      from spot_compare c
      LEFT JOIN spot_moderations m ON m.a_id = c.a_id and m.b_id = c.b_id,
      spots a,
      spots b,
      spot_compare b_c
      where a.id = c.a_id
        and b.id = c.b_id
        and (c.b_id = b_c.a_id or c.a_id = b_c.b_id or c.b_id = b_c.a_id)
        and c.cluster_id <> b_c.cluster_id
        and a.redirect_id is null
        and b.redirect_id is null
        and c.cluster_id in (:current_root)
        and m.id is null', :current_root => cluster_roots)


    links_data.each do |l|
      cluster_links[l['cluster_id1']] ||= []
      cluster_links[l['cluster_id2']] ||= []
      cluster_links[l['cluster_id1']].push l['cluster_id2']
      cluster_links[l['cluster_id2']].push l['cluster_id1']
    end

    @clusters = []
    cluster_roots.each do |root|
      @clusters.push({:id => root})
      if cluster_links[root] then
        cluster_links[root].uniq.each do |id|
          @clusters.push({:id => id, :linked_to => root})
        end
      end
    end

    excluded_spot_ids = {}
    @clusters.each do |cluster|
      #Find all spot_ids for each selected clusters
      cluster[:spot_ids] = Media.select_values_sanitized("select a_id from spot_compare where cluster_id = :cluster_id
        union all select b_id from spot_compare
        where cluster_id = :cluster_id and match_class in ('perfect_match 1', 'perfect_match 2', 'good_match 1', 'good_match 2', 'good_match 3')",
        :cluster_id => cluster[:id]).uniq

      # Identify which spots have been moderated as different from one of the spots of the cluster
      if cluster[:linked_to].nil? && excluded_spot_ids[cluster[:id]].nil? then
        excluded_spot_ids[cluster[:id]] = []
        e = Media.select_all_sanitized('select a_id, b_id from spot_moderations where a_id in (:spot_ids) or b_id in (:spot_ids)', :spot_ids => cluster[:spot_ids])
        e.each do |v|
          excluded_spot_ids[cluster[:id]].push v['a_id']
          excluded_spot_ids[cluster[:id]].push v['b_id']
        end
        excluded_spot_ids[cluster[:id]].uniq!
        excluded_spot_ids[cluster[:id]] -= cluster[:spot_ids]
      end
    end

    @clusters.each do |cluster|
      next if cluster[:linked_to].nil?
      cluster[:spot_ids] -= excluded_spot_ids[cluster[:linked_to]]
    end

  end

  def uncluster_spot_merge
    redirect_to "/404.html" and return if @user.nil? || @user.admin_rights.nil? || @user.admin_rights <= 1

    spot_ids = params[:spot_ids].split(',') rescue []
    master_id = params[:master_id].to_i rescue nil

    master = Spot.find(master_id)
    job = master.merge_into_self spot_ids, @user.id

    respond_to do |format|
      format.json { render :json => {:success => true, :delayed_job => job.id} }
      format.html { redirect_to '/admin/uncluster_spot'}
    end
  end


  def uncluster_spot_distinct
    redirect_to "/404.html" and return if @user.nil? || @user.admin_rights.nil? || @user.admin_rights <= 1

    spots = Spot.where({:id => params[:spot_ids].split(',')}) rescue []
    cluster_id = params[:cluster_id].to_i rescue nil
    cluster_id = nil if cluster_id == 0

    Spot.transaction do
      spots.each do |spot|
        if cluster_id.nil? || spot.id < cluster_id then
          SpotModeration.create :a_id => spot.id, :b_id => cluster_id
        else
          SpotModeration.create :b_id => spot.id, :a_id => cluster_id
        end
      end
    end

    respond_to do |format|
      format.json { render :json => {:success => true, :spot_ids => spots.map(&:id).to_ary, :cluster_id => cluster_id} }
      format.html { redirect_to '/admin/uncluster_spot'}
    end
  end


  def uncluster_spot_ignore
    redirect_to "/404.html" and return if @user.nil? || @user.admin_rights.nil? || @user.admin_rights <= 1

    spot = Spot.find(params[:id])



    spots = Spot.where({:id => params[:spot_ids].split(',')}) rescue []
    cluster_id = params[:cluster_id].to_i rescue nil
    cluster_id = nil if cluster_id == 0

    Spot.transaction do
      spots.each do |spot|
        if cluster_id.nil? || spot.id < cluster_id then
          SpotModeration.create :a_id => spot.id, :b_id => cluster_id
        else
          SpotModeration.create :b_id => spot.id, :a_id => cluster_id
        end
      end
    end

    respond_to do |format|
      format.json { render :json => {:success => true, :spot_ids => spots.map(&:id).to_ary, :cluster_id => cluster_id} }
      format.html { redirect_to '/admin/uncluster_spot'}
    end
  end


  def uncluster_spot_init
    redirect_to "/404.html" and return if @user.nil? || @user.admin_rights.nil? || @user.admin_rights <= 1

    Spot.update_compare_table

    respond_to do |format|
      format.json { render :json => {:success => true} }
      format.html { redirect_to '/admin/uncluster_spot'}
    end

  end




  def check_background_job
    job = Delayed::Job.find(params[:id]) rescue nil
    if job.nil? then
      render :json => {:success => true, :pending => false}
    elsif job.attempts >= Delayed::Worker.max_attempts then
      render :json => {:success => false, :pending => false}
    else
      render :json => {:pending => true}
    end
  end


  def dashboard_stats

    if @user.nil? || @user.admin_rights.nil? || @user.admin_rights < 4
      render :json => {:error => "unauthorized"}
      return
    end

    shops_with_paypal = Media.select_all_sanitized("SELECT COUNT(*) from shops where paypal_id is not null ")[0]['COUNT(*)']
    shops_claimed = Media.select_all_sanitized("SELECT COUNT(DISTINCT(group_id)) from memberships")[0]['COUNT(DISTINCT(group_id))']
    shops_custom = Media.select_all_sanitized("SELECT COUNT(*) from shops left join users on users.shop_proxy_id=shops.id where shops.about_html is not null or users.pict is not null")[0]['COUNT(*)']
    shops_public = Media.select_all_sanitized("SELECT COUNT(*) from shops left join users on users.shop_proxy_id=shops.id")[0]['COUNT(*)']

    shops_with_reviews_now = Media.select_all_sanitized("SELECT COUNT(DISTINCT(shop_id)) from reviews")[0]['COUNT(DISTINCT(shop_id))']
    shops_with_reviews_last_week = Media.select_all_sanitized("SELECT COUNT(DISTINCT(shop_id)) from reviews where created_at < ?", 1.week.ago)[0]['COUNT(DISTINCT(shop_id))']
    shops_with_reviews_last_month = Media.select_all_sanitized("SELECT COUNT(DISTINCT(shop_id)) from reviews where created_at < ?", 1.month.ago)[0]['COUNT(DISTINCT(shop_id))']

    users_now = Media.select_all_sanitized("SELECT COUNT(*) from users where shop_proxy_id is NULL;")[0]['COUNT(*)']
    users_last_week = Media.select_all_sanitized("SELECT COUNT(*) from users where shop_proxy_id is NULL and created_at < ?;", 1.week.ago)[0]['COUNT(*)']
    users_last_month = Media.select_all_sanitized("SELECT COUNT(*) from users where shop_proxy_id is NULL and created_at < ?;", 1.month.ago)[0]['COUNT(*)']

    users_with_dives_now = Media.select_all_sanitized("SELECT COUNT(DISTINCT(user_id)) from dives")[0]['COUNT(DISTINCT(user_id))']
    users_with_dives_last_week = Media.select_all_sanitized("SELECT COUNT(DISTINCT(user_id)) from dives where created_at < ?", 1.week.ago)[0]['COUNT(DISTINCT(user_id))']
    users_with_dives_last_month = Media.select_all_sanitized("SELECT COUNT(DISTINCT(user_id)) from dives where created_at < ?", 1.month.ago)[0]['COUNT(DISTINCT(user_id))']
    users_wow =  (((users_now-users_last_week).to_f / users_last_week.to_f ).to_f*100).round(2).to_f

    user_pictures_now = Media.select_all_sanitized("SELECT COUNT(*) from `pictures` left join users on pictures.user_id = users.id where users.shop_proxy_id is null")[0]['COUNT(*)']
    user_pictures_last_week = Media.select_all_sanitized("SELECT COUNT(*) from `pictures` left join users on pictures.user_id = users.id where users.shop_proxy_id is null and pictures.created_at < ?", 1.week.ago)[0]['COUNT(*)']
    user_pictures_last_month = Media.select_all_sanitized("SELECT COUNT(*) from `pictures` left join users on pictures.user_id = users.id where users.shop_proxy_id is null and pictures.created_at < ?", 1.month.ago)[0]['COUNT(*)']

    shops_claimed_now = Media.select_all_sanitized("SELECT (COUNT(*)) from shops left join users on shops.id = users.shop_proxy_id left join memberships on memberships.group_id = users.id where memberships.group_id is not null")[0]['(COUNT(*))']
    shops_claimed_last_week = Media.select_all_sanitized("SELECT (COUNT(*)) from shops left join users on shops.id = users.shop_proxy_id left join memberships on memberships.group_id = users.id where memberships.group_id is not null and memberships.created_at < ?", 1.week.ago)[0]['(COUNT(*))']
    shops_claimed_last_month = Media.select_all_sanitized("SELECT (COUNT(*)) from shops left join users on shops.id = users.shop_proxy_id left join memberships on memberships.group_id = users.id where memberships.group_id is not null and memberships.created_at < ?", 1.month.ago)[0]['(COUNT(*))']


    render :json => {
      :shops_with_reviews_now => shops_with_reviews_now,
      :shops_with_reviews_last_week => shops_with_reviews_last_week,
      :shops_with_reviews_last_month => shops_with_reviews_last_month,
      :users_now => users_now,
      :users_last_week => users_last_week,
      :users_last_month => users_last_month,
      :users_wow => users_wow,
      :users_with_dives_now => users_with_dives_now,
      :users_with_dives_last_week => users_with_dives_last_week,
      :users_with_dives_last_month => users_with_dives_last_month,
      :shops_claimed_now => shops_claimed_now,
      :shops_claimed_last_week => shops_claimed_last_week,
      :shops_claimed_last_month => shops_claimed_last_month,
      :shops_with_paypal => shops_with_paypal,
      :shops_public => shops_public,
      :shops_custom => shops_custom,
      :shops_claimed => shops_claimed,
      :shops_with_paypal => shops_with_paypal
    }
  end



  private

  def render_users_to_xls(user_list)
    book = Spreadsheet::Workbook.new
    data = book.create_worksheet :name => "optin_users"
    logger.debug "exporting #{user_list.count} users to xls file"
    user_list.each_with_index do |user, i|
      if user.last_name.nil?
        data.row(i).push user.contact_email, user.vanity_url, user.nickname, ""
      else
        data.row(i).push user.contact_email, user.vanity_url, user.last_name, user.first_name
      end
    end
    blob = StringIO.new("")
    book.write(blob)
    return blob
  end
  def render_users_to_csv(user_list)
    blob = StringIO.new("")
    logger.debug "exporting #{user_list.count} users to csv file"
    user_list.each_with_index do |user, i|
      if user.last_name.nil?
        blob.puts "#{user.contact_email},#{user.vanity_url},#{user.nickname},"
      else
        blob.puts "#{user.contact_email},#{user.vanity_url},#{user.last_name},#{user.first_name}"
      end
    end
    blob.rewind
    return blob
  end

  def adapt_spot_params
    ## will adapt spot params between admin and wizard
    ##data structure in admin is a wee bit different, this adapts it to the one used in wizard
    params[:name] =  params[:spot]["name"]
    params[:lat] =  params[:spot]["lat"]
    params[:lng]=  params[:spot]["long"]
    params[:zoom] =  params[:spot]["zoom"]
    params[:country] = params["country_code"]
    params[:location] = params["location"]
    params[:region] = params["region"]

  end

end
