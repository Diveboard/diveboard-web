require 'validation_helper'

class TagController < ApplicationController

  def redirect
    tag = Tag.fromshake(params[:shaken_id]) rescue nil
    url = tag.redirect_url rescue Tag::DEFAULT_URL
    redirect_to url
  end

  def check_status
    begin
      tag = Tag.fromshake(params[:shaken_id])
    rescue
      render :json => {:success => true, :status => :bad_value}
      return
    end
    begin
      if tag.user_id.nil?
        render :json => {:success => true, :status => :available}
        return
      else
        render :json => {:success => true, :status => :assigned, :user_id => tag.user.shaken_id}
        return
      end
    rescue
      render api_exception $!
    end
  end
end
