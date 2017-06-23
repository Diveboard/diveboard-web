require 'json'

class V2::ExploreController < V2::ApplicationController

  def gallery
    @ga_page_category = "gallery_v2"
    page_nb = 1
    offset = 0
    page_size = 30
    if params[:page].to_i > 0 then
      page_nb = params[:page].to_i
      offset = page_size * (page_nb-1)
    end

    pictures = []

    if page_size * page_nb < 500 then
      pictures = Picture.unscoped.includes(:picture_album_pictures => {:dive => :spot}).where('dives.privacy=0').offset(offset).limit(page_size).order('pictures.great_pic DESC, ADDDATE(pictures.created_at, interval pictures.id%7 day) DESC')
    end

    if !params[:area_id].blank? then
      area = Area.find(params[:area_id]) rescue nil
      if area then
        pictures = pictures.where('spots.lat between :latmin and :latmax and spots.long between :lngmin and :lngmax', latmin: area.minLat, latmax:area.maxLat, lngmin: area.minLng, lngmax: area.maxLng)
      end
    end

    if params[:append] then
      render 'v2/explore/gallery_append', :layout => false, :locals => {:pictures => pictures, :page_nb => page_nb}
    else
      render :layout => 'v2', :locals => {:pictures => pictures, :page_nb => page_nb}
    end
  end
end
