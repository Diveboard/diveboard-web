require 'money'
require 'eu_central_bank'
require 'shop'

class ShopWidgetsController < ApplicationController

  #before_filter :init_fbconnection #init the graph connection and everyhting user related
  before_filter :init_logged_user, :prevent_browser_cache #init the graph connection and everyhting user related
  #use the application layout which has header and footer
  #require 'rubygems'
  layout 'widget_layout'

  def medium
    @ga_page_category = "widget_pro"
    params[:shaken_id] = nil unless params[:shaken_id].is_a?(String) && params[:shaken_id][0] == 'K'
    @shop = Shop.fromshake params[:shaken_id] rescue nil
    @owner = @shop.user_proxy rescue nil
    if @owner.nil? || @shop.nil?
      render 'layouts/404', :layout => false
      return
    end

    logger.debug request.env.inspect

    cacheTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
    modified_at = (@shop.reviews.map(&:updated_at) + [@shop.updated_at]).max rescue Time.now
    logger.debug "request from #{request.remote_ip} --- cache time=#{cacheTime}  --- last modification time #{modified_at}"

    # if the client already has the widget and it's still valid, don't bother about anything else
    if cacheTime and modified_at <= cacheTime then
      return render :nothing => true, :status => 304
      return
    end

    expires_in 3.years, :public => true
    response.headers['Cache-Control'] = "public, must-revalidate, proxy-revalidate"
    response.headers['Last-Modified'] = modified_at.rfc2822
    response.headers['Pragma'] = ''
  end

  def large
    @ga_page_category = "widget_pro"
    params[:shaken_id] = nil unless params[:shaken_id].is_a?(String) && params[:shaken_id][0] == 'K'
    @shop = Shop.fromshake params[:shaken_id] rescue nil
    @owner = @shop.user_proxy rescue nil
    if @owner.nil? || @shop.nil?
      render 'layouts/404', :layout => false
      return
    end

    @nb_reviews = params[:n].to_i || 5 rescue 5
    @nb_reviews = 5 if @nb_reviews < 3 || @nb_reviews > 7

    cacheTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
    modified_at = (@shop.reviews.map(&:updated_at) + [@shop.updated_at]).max rescue Time.now
    logger.debug "request from #{request.remote_ip} --- cache time=#{cacheTime}  --- last modification time #{modified_at}"

    # if the client already has the widget and it's still valid, don't bother about anything else
    if cacheTime and modified_at <= cacheTime then
      return render :nothing => true, :status => 304
      return
    end

    expires_in 3.years, :public => true
    response.headers['Cache-Control'] = "public, must-revalidate, proxy-revalidate"
    response.headers['Last-Modified'] = modified_at.rfc2822
    response.headers['Pragma'] = ''
  end



end
