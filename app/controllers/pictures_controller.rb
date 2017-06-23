require 'filemagic'
require 'open-uri'
require 'mini_exiftool'

class PicturesController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache

  def read
    ### '/:vanity_url/pictures/:picture_id' => 'pictures#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :picture_id => /[0-9]*/
    begin
      picture = Picture.find(params[:picture_id]);
      raise DBArgumentError.new "This Picture does not belong to any dive" if picture.dive.nil?
      raise DBArgumentError.new "Wrong dive owner" if picture.dive.user.vanity_url.downcase != params[:vanity_url].downcase

      if picture.dive.privacy == 0 || (picture.dive.privacy==1 && !@user.nil? && @user.id == picture.dive.user.id)
        ## The picture exists, and we're allowed to see the dive
        logger.debug "Alles Klar, we can show the picture in the logbook"
        #redirect_to :action => 'logbook#read', :vanity_url => params[:vanity_url] , :dive => picture.dive.id, :picture => picture.id
        redirect_to picture.dive.permalink, :picture => picture.id
        return
      else
        raise DBArgumentError.new "You are not allowed to see this picture"
      end
    rescue Exception => e
      ## this is a 404 !
      logger.debug e
      render 'layouts/404', :layout => false
      return
    end
  end

  def write
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


      file = Tempfile.new('dive_picture')
      file.binmode
      if params[:from_tmp_file].nil? then
        ajax_upload = params[:qqfile].is_a?(String)
        filename = ajax_upload  ? params[:qqfile] : params[:qqfile].original_filename
        extension = filename.split('.').last
        # Creating a temp file
        if ajax_upload then
          #check if the body has been posted as base64
          body = request.body.read
          dec = body.match /^data:image\/(jpeg|png);base64,/
          if dec then
            file.write(Base64.decode64(body[(dec[0].length)..-1]))
          else
            file.write(body)
          end
        else
          file.write(params[:qqfile].read)
        end
        #file.close(unlink_now=false)
      else
        file.write(File.read("public/tmp_upload/"+params[:from_tmp_file].gsub('/','')))
      end

      if user.storage_used[:orphan_pictures] + file.size > Rails.application.config.max_orphan_size then
        raise DBArgumentError.new "You have reached the maximum upload per day"
      elsif user.quota_type == 'per_user' && user.storage_used[:dive_pictures] > user.quota_limit then
        raise DBArgumentError.new "You have reached your quota of upload available"
      end

      fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
      Rails.logger.debug("DEBUGGING BODY ------------------------------------------------------------------------------------------------------------") 
      Rails.logger.debug(file.path)
      content_type = fm.file(file.path)
      Rails.logger.debug(content_type)
      if content_type.match /image/ then

        #crop image if required
        if params[:crop_x0] && params[:crop_y0] && params[:crop_width] && params[:crop_height] then
          crop_image(file.path, params[:crop_x0], params[:crop_y0], params[:crop_width], params[:crop_height])
        end

        #save the image
        pic = Picture.create_image :path => file.path, :user_id => user.id

        #create thumb right now for formats that are not supported by all browsers
        pic.cache_image_without_delay unless content_type.match /^image.(jpeg|png|gif)$/

      elsif content_type.match(/application\/pdf/) then

        #save the image
        pic = Picture.create_image :path => file.path, :user_id => user.id

        #create thumb right now
        pic.cache_image_without_delay

      elsif content_type.match(/video/) || content_type.match(/application.ogg/) then
        #create the thumb
        thumb = Tempfile.new([ 'dive_video_thumb', '.jpg' ])
        logger.debug `ffmpeg -i '#{file.path}' -vframes 1 -ss 1 -vf "scale='min(1280, iw*960/ih):min(960, ih*1280/iw)'" '#{thumb.path}' 2>&1`
        if $?.exitstatus != 0 then
          raise DBArgumentError.new "Error while generating thumbnail"
        end
        raise DBArgumentError.new "Thumb could not be generated" unless thumb.size > 0
        #save the INTENRET video
        pic = Picture.create_video :path => file.path, :user_id => @user.id, :poster => thumb.path

      else
        raise DBArgumentError.new 'Unrecognized file format'
      end

      #Setting the album if provided
      album_id = nil
      case params[:album]
      when Integer then
        album_id = params[:album] if Album.find(params[:album]).user_id == user.id rescue false
      when 'shop_ads' then
        album_id = Album.where(:kind => 'shop_ads', :user_id => user.id).first.id rescue nil
        album_id ||= Album.create(:user_id => user.id, :kind => 'shop_ads').id
      when 'shop_cover' then
        album_id = Album.where(:kind => 'shop_cover', :user_id => user.id).first.id rescue nil
        album_id ||= Album.create(:user_id => user.id, :kind => 'shop_cover').id
      when 'shop_gallery' then
        album_id = Album.where(:kind => 'shop_gallery', :user_id => user.id).first.id rescue nil
        album_id ||= Album.create(:user_id => user.id, :kind => 'shop_gallery').id
      when 'avatar' then
        album_id = Album.where(:kind => 'avatar', :user_id => user.id).first.id rescue nil
        album_id ||= Album.create(:user_id => user.id, :kind => 'avatar').id
        user.update_attribute :pict, true
      when 'wallet' then
        album_id = Album.where(:kind => 'wallet', :user_id => user.id).first.id rescue nil
        album_id ||= Album.create(:user_id => user.id, :kind => 'wallet').id
      when String then
        id = Integer(params[:album], 10) rescue nil
        album_id = id if id && Album.find(params[:album]).user_id == user.id rescue false
      else nil
      end
      pic.append_to_album album_id unless album_id.nil?

      pic.reload
      file.close

      flavour = params[:flavour].to_sym || :public rescue :public
      Rails.logger.debug "Using flavour #{flavour}"
      json = {
        :success => true,
        :picture => {:id => pic.id, :image=>pic.medium, :link => pic.href, :size => pic.size, :just_uploaded => true },
        :result => pic.to_api(flavour, :private => true)
      }

      Rails.logger.debug json
      render :json => json, :content_type => "text/html"
    rescue
      logger.error "Error while receiving and creating image #{$!.message}"
      logger.debug $!.backtrace.join("\n")
      begin
        pic.destroy unless pic.nil?
      rescue
        #do nothing here
      end
      file.close unless file.nil?
      render :json => {:success => false, :message => $!.message}, :content_type => "text/html"
    end
  end

  def read_video
    begin
      picture = Picture.find(params[:picture_id]);
      raise DBArgumentError.new "This Picture does not belong to any dive" if picture.dive.nil?
      raise DBArgumentError.new "Wrong dive owner" if picture.dive.user.vanity_url.downcase != params[:vanity_url].downcase

      if picture.dive.privacy == 0 || (picture.dive.privacy==1 && !@user.nil? && @user.id == picture.dive.user.id)
        ## The picture exists, and we're allowed to see the dive
        logger.debug "Alles Klar, we can show the picture in the logbook"
        #redirect_to :action => 'logbook#read', :vanity_url => params[:vanity_url] , :dive => picture.dive.id, :picture => picture.id
        render :layout => false, :locals => {:picture => picture}
        return
      else
        raise DBArgumentError.new "You are not allowed to see this picture"
      end
    rescue Exception => e
      ## this is a 404 !
      logger.debug e
      render 'layouts/404', :layout => false
      return
    end
  end

  def redirect
  begin
    logger.debug "picture redirect on #{params[:shaken_id]}"
    p = Picture.fromshake(params[:shaken_id])
    logger.debug "found picture #{p.id}"
    if p.media == "video"
      case params[:format]
      when "webm"
        redirect_to p.webm
      when "mp4"
        redirect_to p.mp4
      end
    else
      case params[:format]
      when "medium"
        redirect_to p.medium
      when "large"
        redirect_to p.large
      when "original"
        redirect_to p.original
      when "thumbnail"
        redirect_to p.thumbnail
      when "thumb"
        redirect_to p.thumb
      else
        redirect_to p.medium
      end
    end
    return
  rescue Exception => e
      ## this is a 404 buddy !
      logger.debug e
      render 'layouts/404', :layout => false
      return
  end

  end

  def video_redirect
    begin
      picture = Picture.find(params[:picture_id]);
      raise DBArgumentError.new "This is not a vide" if picture.media != "video"
      raise DBArgumentError.new "This Picture does not belong to any dive" if picture.dive.nil?
      raise DBArgumentError.new "Wrong dive owner" if picture.dive.user.vanity_url.downcase != params[:vanity_url].downcase
      raise DBArgumentError.new "Picture is in a private dive" if picture.dive.privacy != 0

      ## The video exists, and we're allowed to see the dive
      logger.debug "Alles Klar, we can redirect to the video"
      respond_to do |format|
        format.mp4{
          raise DBArgumentError.new "video not ready" if picture.video_url[:mp4].nil?
          redirect_to picture.video_url[:mp4]
          return
        }
        format.webm{
          raise DBArgumentError.new "video not ready" if picture.video_url[:webm].nil?
          redirect_to picture.video_url[:webm]
          return
        }
        format.html{
          raise DBArgumentError.new "this is not serving HTML!"
        }
      end

    rescue Exception => e
      ## this is a 404 !
      logger.debug e
      respond_to do |format|
        format.html{
          render 'layouts/404', :layout => false
          return
        }
        format.mp4 {render :nothing => true , :content_type => 'video/mp4'}
        format.webm {render :nothing => true , :content_type => 'video/webm'}
      end
    end
  end

  def download
    begin
      logger.debug "picture download for #{params[:shaken_id]}"
      p = Picture.fromshake(params[:shaken_id])
      logger.debug "found picture #{p.id}"

      ext = Mime::Type.file_extension_of p.original_content_type
      ext = 'bin' if ext.blank?

      url = p.original_document_url

      if url.nil? then
        render 'layouts/404', :layout => false
        return
      end

      io = open(url)
      send_data io.read, :filename => "diveboard_doc_#{p.shaken_id}.#{ext}", :type => 'application/octet-stream'
      io.close
    rescue Exception => e
      logger.debug e
      render 'layouts/404', :layout => false
      return
    end
  end


  def picture_browser
    page_nb = 1
    offset = 0
    page_size = 30
    if params[:page].to_i > 0 then
      page_nb = params[:page].to_i
      offset = page_size * (page_nb-1)
    end

    pictures = []

    if page_size * page_nb < 500 then
      pictures = Picture.unscoped.includes(:picture_album_pictures => :dive).where('dives.privacy=0').offset(offset).limit(page_size).order('pictures.great_pic DESC, ADDDATE(pictures.created_at, interval pictures.id%7 day) DESC')
    end

    @pagename = "GALLERY"
    @ga_page_category = 'gallery'

    if params[:no_layout] then
      render :layout => false, :locals => {:pictures => pictures, :page_nb => page_nb}
    else
      render :layout => 'main_layout', :locals => {:pictures => pictures, :page_nb => page_nb}
    end
  end

def fbvideo_proxy
  @width = params[:width] || 640
  @height = params[:height] || 360
  @id = params[:id]

  if @id.nil?
    render 'layouts/404', :layout => false
    return
  else
    return
    render :layout => false
  end
end




private

  def crop_image(filepath, x0, y0, width, height)
    begin
      image = MiniMagick::Image.open(filepath)
      logger.debug "using image #{filepath}"
      logger.debug "cropping #{width}x#{height}+#{x0}+#{y0}"
      image.crop "#{width}x#{height}+#{x0}+#{y0}"

      image.format "jpg"
      image.write filepath
    rescue
      logger.error "the cropping failed..."+$!.message
      logger.debug $!.backtrace.join("\n")
    end
  end

end
