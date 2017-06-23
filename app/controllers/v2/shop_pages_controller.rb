class V2::ShopPagesController < V2::ApplicationController
	def index
		@edit_flag = false
		@page = :shop
		@ga_page_category = "shop_v2"
		#scss = render_to_string(:partial => 'shop_pages', locals: { percent: 83 }, formats: :scss)
		#@css = Sass::Engine.new(scss, syntax: :scss).render


		if params[:vanity_url] != nil then
			#retrieve the user using the vanity url
			@owner = User.find_by_vanity_url(params[:vanity_url])
		end
		if @owner == nil || @owner.shop_proxy_id == nil then
			#the user doesn't exist
			logger.debug "apparently can't find the shop with url #{params[:vanity_url]} "
      		render 'layouts/404', :layout => false
      		return
		end


		@shop = @owner.shop_proxy
		@reviews = @shop.public_reviews.order("id DESC").limit(6)

		@user_owns_shop = check_ownership
		@reviews_page_nb = 1
    if params[:append] then
      append_content
      return true
    end

		@spots = @shop.spots
		@cover_pictures = Album.find_by_id(@shop.user_proxy.cover_album_id).pictures
		@gallery_pictures = Album.find_by_id(@shop.user_proxy.gallery_album_id).pictures
		if @gallery_pictures.size == 0
			@gallery_pictures = @shop.dive_pictures
		end
		@recent_dives = @shop.public_dives
		@faqs = @shop.faqs.where("answer IS NOT NULL AND answer != ''")
		if !@user.nil?
			@is_following = @user.follow? shop_id: @shop.id
		else
			@is_following = false
		end
				if I18n.locale == :fr
			@languages_selected = @shop.i18nLanguages("fr")
		else
			@languages_selected = @shop.i18nLanguages("en")
		end

	end

	def buy_a_product
		if params[:vanity_url] != nil then
			#retrieve the user using the vanity url
			@owner = User.find_by_vanity_url(params[:vanity_url])
		end
		if @owner == nil || @owner.shop_proxy_id == nil then
			#the user doesn't exist
			logger.debug "apparently can't find the shop with url #{params[:vanity_url]} "
      		render 'layouts/404', :layout => false
      		return
		end
		@shop = @owner.shop_proxy
		if params[:subject] != nil then
			@subject = params[:subject]
		end
		if params[:message] != nil then
			@message = params[:message]
		end
		NotifyShop.notify_buy(@shop, @user, @message, @subject).deliver
		render :json => {:success => true}
	end

	def check_ownership
		# Check Admin
		if !@user.nil? && @user.admin_rights >= 4
			return true
		end
		owner = nil
		if params[:vanity_url] != nil then
			#retrieve the user using the vanity url
			owner = User.find_by_vanity_url(params[:vanity_url])
		end
		if owner == nil || owner.shop_proxy_id == nil then
      return false
		end

		shop = owner.shop_proxy
		user_owns_shop = false
		if !@user.nil? && @user.shops_owned.count > 0
			@user.shops_owned.each do |s|
				if s.id == shop.id
					user_owns_shop = true
				end
			end
		end
		return user_owns_shop
	end

	def edit
		user_owns_shop = check_ownership
		if !user_owns_shop
			render 'layouts/404', :layout => false
			return
		end
		index
		@faqs = @shop.faqs
		if I18n.locale == :fr
			@languages = I18nLanguages.where(lang: :fr)
			@languages_selected = @shop.i18nLanguages("fr")
		else
			@languages = I18nLanguages.where(lang: :en)
			@languages_selected = @shop.i18nLanguages("en")
		end
		@edit_flag = true
		@category = params[:category]

    if params[:basket_id] then
      logger.debug "trying to find basket #{params[:basket_id]}"
      @basket = Basket.decode_reference(params[:basket_id]) rescue Basket.fromshake(params[:basket_id])
      logger.debug "Basket: #{@basket.inspect}"
      @basket = nil unless @basket.shop == @shop
    else
      @basket = nil
    end

    if params[:message_id] then
      logger.debug "trying to find message #{params[:message_id]}"
      @message = InternalMessage.fromshake(params[:message_id])
      logger.debug "Message: #{@message.inspect}"
      @message = nil unless @message.to_id == @shop.user_proxy.id || @message.from_id == @shop.user_proxy.id || @message.from_group_id == @shop.user_proxy.id

      if @message.in_reply_to.is_a? Basket then
        @basket ||= @message.in_reply_to
      end

    else
      @message = nil
    end

	end

	def delete_logo_picture
    begin
      raise DBArgumentError.new 'User must be logged in' if @user.nil?
      user = @user
      if !params[:user_id].blank? then
        user = User.find(params[:user_id].to_i) rescue nil
        raise DBArgumentError.new "Unknown user", user_id: params[:user_id] if user.nil?
      end
      if !@user.can_edit?(user) then
        raise DBArgumentError.new "Cannot create pic with user", owner_id: user.id, user_id: @user.id
      end
    end
    logger.debug "USER = >>>>>>> " + @user.id.to_s
		user.pict = false
		user.save
		render :json => {:success => true}
	end

	def share_to_friend
		if params[:vanity_url] != nil then
			#retrieve the user using the vanity url
			@owner = User.find_by_vanity_url(params[:vanity_url])
		end
		if @owner == nil || @owner.shop_proxy_id == nil then
			#the user doesn't exist
			logger.debug "apparently can't find the shop with url #{params[:vanity_url]} "
      		render 'layouts/404', :layout => false
      		return
		end
		@shop = @owner.shop_proxy
		if params[:subject] != nil then
			@subject = params[:subject]
		end
		if params[:message] != nil then
			@message = params[:message]
		end
		if params[:from] != nil then
			@from = params[:from]
		end
		if params[:to] != nil then
			@to = params[:to]
		end

		NotifyUser.share_to_friend(@from, @to, @subject, @message, @shop).deliver
		render :json => {:success => true, :param => params}
	end

	def review
		redirect_to '/pro/' + params[:vanity_url] + '#shop_reviews', :status => 301
	end

	def profile
		redirect_to '/pro/' + params[:vanity_url], :status => 301
	end

  def append_content
    nb_reviews_page = 5

    if params[:type] == 'review' then
      if params[:page].to_i > 0 then
        @reviews_page_nb = params[:page].to_i
        offset = nb_reviews_page * (@reviews_page_nb.to_i - 1)
      end
      @reviews_page_nb = params[:page]
      reviews = []
      #reviews = @area.dives_order_by_overall_and_notes(nb_reviews_page, offset)
      reviews =@shop.public_reviews.order("id DESC").limit(nb_reviews_page).offset(offset)
      render 'v2/shop_pages/reviews_append', :layout => false, :locals => {:reviews => reviews}
    end
  end

  def message
  	index
    if params[:message_id] then
      logger.debug "trying to find message #{params[:message_id]}"
      @message = InternalMessage.fromshake(params[:message_id])
      logger.debug "Message: #{@message.inspect}"
      @message = nil unless @message.to_id == @shop.user_proxy.id || @message.from_id == @shop.user_proxy.id || @message.from_group_id == @shop.user_proxy.id

      if @message.in_reply_to.is_a? Basket then
        @basket ||= @message.in_reply_to
      end

    else
      @message = nil
    end
    if @message.to_id == @shop.user_proxy.id then @customer = @message.from
 	else @customer = @message.to
  	end
    render :layout => false, :partial => "v2/shop_pages/edit/customer_view", :locals => {:highlight => @message, :shop => @shop, :customer => @customer}
  end
	def basket
		index
		if params[:basket_id] then
	      logger.debug "trying to find basket #{params[:basket_id]}"
	      @basket = Basket.decode_reference(params[:basket_id]) rescue Basket.fromshake(params[:basket_id])
	      logger.debug "Basket: #{@basket.inspect}"
	      logger.debug "Shop: #{@shop.inspect}"
	      @basket = nil unless @basket.shop == @shop
	    else
	      @basket = nil
	    end
		if @basket then
		  begin
		    render :partial => "v2/shop_pages/edit/basket_"+@basket.status, :locals => {:basket => @basket, :highlight => @message}
		  rescue ActionView::MissingTemplate => e
		    render :partial => "v2/shop_pages/edit/basket_default", :locals => {:basket => @basket, :highlight => @message}
		  end
		end
	end
end

