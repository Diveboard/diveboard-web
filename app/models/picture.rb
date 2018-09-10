require 'fileutils'
require 'open-uri'
require 'mini_exiftool'
require 'delayed_job'
require 'filemagic'

class Picture < ActiveRecord::Base
  extend FormatApi

  #WTF IS THIS PICTURE ?
  #media :=> it can be an image or a video
  #origin  :=> uploaded directly to diveboard or taken from somewhere else : "local" or "remote"

  #how do i put it in my page?
  ## picture : ONLY use the .medium or .thumbnail values
  ## video : ONLY use the .player to get a video player in pseudo-html5 code if local or a flash player if remote

  ##additional stuff
  ## .href will link to the SOURCE of the picture if any i.e. the web page it was sniffed from
  ## .url link to an "original" picture nil if local (in that case the orinal_id or original_path should be used)
  ## original_path : where there LOCAL picture has been uploaded - can be used as last resort fallback to build a link to that picture ==> TODO also save the original external image with the same mechanics
  ## .cache is used to build the link to the medium and thumb images + "_m.jpg" + "_s.jpg"

  #                  Picture                           Uploaded picture                     Video                                                          Uploaded Video
  # url      :  URL to object loaded (flickr/jpg)   URL to original saved (local)     URL to original of jpeg thumb marked with video icon     URL to original jpg thumb marked
  # href     :  URL to flickr web page              URL to original saved (local)     url to youtube web page                                  URL to resized video ? (local)
  # cache    :  path to cache thumbs                path to original saved            path to cached jpeg thumbs                               path to cached jpeg thumbs
  #
  # used for cee:  medium                           medium                            href                                                     href

  #belongs_to :dive, :class_name => 'Dive'
  belongs_to :eolsname
  belongs_to :cloud_thumb, :foreign_key => 'thumb_id', :class_name => 'CloudObject'
  belongs_to :cloud_large, :foreign_key => 'large_id', :class_name => 'CloudObject'
  belongs_to :cloud_small, :foreign_key => 'small_id', :class_name => 'CloudObject'
  belongs_to :cloud_medium, :foreign_key => 'medium_id', :class_name => 'CloudObject'
  belongs_to :cloud_large_fb, :foreign_key => 'large_fb_id', :class_name => 'CloudObject'
  belongs_to :cloud_original_video, :foreign_key => 'original_video_id', :class_name => 'CloudObject'
  belongs_to :cloud_original_image, :foreign_key => 'original_image_id', :class_name => 'CloudObject'
  belongs_to :cloud_webm, :foreign_key => 'webm_id', :class_name => 'CloudObject'
  belongs_to :cloud_mp4, :foreign_key => 'mp4_id', :class_name => 'CloudObject'
  belongs_to :user
  has_many :picture_album_pictures
  default_scope order("pictures.updated_at desc")
  before_destroy :destroy_thumbs

  validates_inclusion_of :media, :in => %w(image video), :allow_nil => false

  has_and_belongs_to_many :eolsnames,
                          :join_table => 'pictures_eolcnames',
                          :association_foreign_key => 'sname_id',
                          :foreign_key => 'picture_id',
                          :uniq => true

  has_and_belongs_to_many :eolcnames,
                          :join_table => 'pictures_eolcnames',
                          :association_foreign_key => 'cname_id',
                          :foreign_key => 'picture_id',
                          :uniq => true

  has_one :fb_comment, :class_name => "FbComments", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id, :order => "fb_comments.updated_at DESC"
  has_many :fb_likes, :class_name => "FbLike", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id



  define_format_api :public => [
          :thumbnail, :medium, :large, :small, :notes, :media, :player, :full_redirect_link, :fullpermalink, :permalink, :created_at
          ],
      :private => [:id, :cropable, :original_document_url, :original_document_download_url],
      :mobile => [:id],
      :search_light => [ :medium ],
      :search_full => []

  define_api_updatable_attributes %w( notes species )

  def is_private_for?(options = {})
    begin
      return true if self.user_id.nil? #well.... not really....
      return true if options[:private]
      return true if options[:caller].id == self.user_id rescue false
      return true if self.user.is_private_for?(options) rescue false
      return false
    rescue
      return false
    end
  end

  def dive
    begin
      return Dive.joins("LEFT JOIN picture_album_pictures ON picture_album_pictures.picture_album_id=dives.album_id").where("picture_album_pictures.picture_id = ?", self.id).first
    rescue
      return nil
    end
  end

  def blogpost
    begin
      return BlogPost.joins("LEFT JOIN wikis ON wikis.source_id=blog_posts.id LEFT JOIN picture_album_pictures ON picture_album_pictures.picture_album_id=wikis.album_id ").where("picture_album_pictures.picture_id = ? and wikis.source_type LIKE 'BlogPost'", self.id).first
    rescue
      return nil
    end
  end

  alias :user_activerecord :user
  def user
    begin
      return self.user_activerecord unless self.user_activerecord.nil?
      return self.dive.user
    rescue
      return nil
    end
  end

  def self.create_image opts={}
    ##creates a new image from a url or file args:
    ##:url to an image somewhere or a :path to a local image
    ##:user_id

    raise DBArgumentError.new "no link to pictures" if opts[:url].blank? && opts[:path].blank?
    if !opts[:path].blank?
      imagefile = open(opts[:path])
    else
      ## we must check the url
      imagefile = nil
      begin
        #1 Check if the url points to an imagefile
        MiniMagick::Image.open(opts[:url])
      rescue
        #2 darn - this url is not an image !!!
        #let's try and fix this ;)
        begin
          if (fid=opts[:url].match(/flickr\.com\/[^\/]+\/[^\/]+\/([^\/]+)/))
            require 'flickraw'
            FlickRaw.api_key= FLICKR_KEY
            FlickRaw.shared_secret= FLICKR_SECRET
            begin
              #this may fail if for instance the account is not paid anymor
              fid_o = FlickRaw.url_o(flickr.photos.getInfo(:photo_id => fid[1]))
            rescue
              fid_o = FlickRaw.url_b(flickr.photos.getInfo(:photo_id => fid[1]))
            end
            opts[:href] = opts[:url]
            opts[:url] = fid_o
          else
            raise DBArgumentError
          end
        rescue
          raise DBArgumentError.new "url is invalid"
        end
      end
    end
    raise DBArgumentError.new "no picture owner" if opts[:user_id].blank?
    pic = Picture.create {|p|
        p.url = opts[:url] || nil
        p.original_image_path = opts[:path] || nil
        if !imagefile.nil?
          p.size = imagefile.size
        else
          p.size = 0
        end
        p.user_id = opts[:user_id].to_i
        p.href = opts[:href] || nil
        p.media = "image" ## this can be overwritten to video if it's a youtube video
      }
    logger.debug "we have created a new media of type #{pic.media} with id #{pic.id}"
    pic.finalize_creation

    return pic
  end

  def self.create_youtube_video opts={}
    raise DBArgumentError.new "no link to pictures" if opts[:url].blank? && opts[:path].blank?
    raise DBArgumentError.new "wrong youtube href" if (check_youtube_url opts[:href]).nil?
    return Picture.create_internet_video opts
  end
  def self.create_dailymotion_video opts={}
    raise DBArgumentError.new "no link to pictures" if opts[:url].blank? && opts[:path].blank?
    raise DBArgumentError.new "wrong youtube href" if (check_dailymotion_url opts[:href]).nil?
    return Picture.create_internet_video opts
  end

  def self.create_vimeo_video opts={}
    raise DBArgumentError.new "no link to pictures" if opts[:url].blank? && opts[:path].blank?
    raise DBArgumentError.new "wrong vimeo href" if (check_vimeo_url opts[:href]).nil?
    return Picture.create_internet_video opts
  end
  def self.create_facebook_video opts={}
    raise DBArgumentError.new "no link to pictures" if opts[:url].blank? && opts[:path].blank?
    raise DBArgumentError.new "wrong facebook video href" if (check_facebook_url opts[:href]).nil?
    return Picture.create_internet_video opts
  end

  def self.create_internet_video opts={}
    ## must be called with checked hrefs (i.e. by create_dailymotion_video)
    if !opts[:path].blank?
      imagefile = open(opts[:path])
    else
      imagefile = nil
    end
    raise DBArgumentError.new "no picture owner" if opts[:user_id].blank?
    pic = Picture.create {|p|
        p.url = opts[:url] || nil
        p.original_image_path = opts[:path] || nil
        if !imagefile.nil?
          p.size = imagefile.size
        else
          p.size = 0
        end
        p.user_id = opts[:user_id].to_i
        p.href = opts[:href]
        p.media = "video"
      }
    logger.debug "we have created a new internet video media of type #{pic.media} with id #{pic.id}"
    pic.finalize_creation

    return pic
  end

  def self.create_video opts={}
    ##creates a new video from a file path
    ##:path to a local video, :poster is a path to the video's poster
    ##:user_id , :size
    raise DBArgumentError.new "no path to poster image" if opts[:poster].blank?
    raise DBArgumentError.new "no path to video" if opts[:path].blank?
    raise DBArgumentError.new "no picture owner" if opts[:user_id].blank?
    videofile = open(opts[:path])
    pic = Picture.create {|p|
        p.original_image_path = opts[:poster]
        p.original_video_path = opts[:path]
        p.size = videofile.size
        p.user_id = opts[:user_id].to_i
        p.href = opts[:href] || nil
        p.media = "video"
      }
      logger.debug "we have created a new media of type #{pic.media} with id #{pic.id}"
      pic.finalize_creation
    return pic
  end


  def finalize_creation
    logger.debug "START of finalization of the creation of #{media} with id #{id}"
    self.auto_rotate
    self.save_original
    self.get_exif_data
    self.cache_image
    if media == "video" && Picture.check_youtube_url(href).nil? && Picture.check_dailymotion_url(href).nil? && Picture.check_vimeo_url(href).nil? && Picture.check_facebook_url(href).nil?
      #this may be a real video
      self.video_resize
    end
    self.update_size
    logger.debug "END of finalization of the creation of #{media} with id #{id}"
  end

  def auto_rotate
    begin
      ##auto rotate uploaded files that have the rotation as an EXIF attribute
      if !self.original_image_path.nil? && File.exists?(self.original_image_path)
        jpeg = self.original_image_path
      else
        return false
      end

      filename = "/user_images/image-cache-#{self.id}"

      logger.debug "auto rotating image #{filename} from #{jpeg}"
      #open("public"+filename+".jpg", 'wb') do |file|
      #   file << open(jpeg).read
      # end
      image_path = jpeg
      image = MiniMagick::Image.open(image_path)
      #image.format 'jpg'
      image.auto_orient
      image.write image_path
    rescue
      logger.debug "FAILED auto rotating image "+$!.message
    end
  end

  def update_size
    begin
      self.size = open(self.original_image_path).size
      if !self.original_video_path.nil?
        self.size = open(self.original_video_path).size
      end
      self.save
    rescue
      logger.debug "Could not update size of the picture because "+$!.message
      self.size = 0
      self.save
    end
  end

  def get_exif_data
    begin
      ex = nil
      begin
        if File.exists?(self.original_image_path)
          ex = MiniExiftool.new self.original_image_path
        end
      rescue
        logger.debug "exif data from original_image_path failed"
      end
      begin
        if ex.nil? && !self.original_image_id.nil?
          ex = MiniExiftool.new open(self.cloud_original_image.url).path
        end
      rescue
        logger.debug "exif data from original_image_id failed"
      end
      begin
        if ex.nil? && !self.url.nil?
          ex = MiniExiftool.new open(self.url).path
        end
      rescue
        logger.debug "exif data from url failed"
      end
      if ex.nil?
        raise DBArgumentError.new "Could not find an original picture"
        ex ={}
      end
    rescue
      logger.debug "could not get ex data "+$!.message
      begin
        ex = JSON.parse(self.ex) || {}
      rescue
        ex = {}
      end
    end
    p = Picture.find(self.id)

    # Need to filter binary values for JSON serialization
    ex2 = {}
    ex.as_json.each do |a, b| ex2[a]=b if begin b.to_json rescue nil end end
    p.exif = ex2.to_json
    p.save!
    return ex
  end
  handle_asynchronously :get_exif_data

  def get_image size="medium"
    if size == "thumb"
      return self.cloud_thumb.url if !self.thumb_id.nil?
      return "#{ROOT_URL.chop}#{cache}_t.jpg" if File.exists?("public#{cache}_t.jpg")
    elsif size == "small"
      return self.cloud_small.url if !self.small_id.nil?
      return "#{ROOT_URL.chop}#{cache}_s.jpg" if File.exists?("public#{cache}_s.jpg")
    elsif size == "medium"
      return self.cloud_medium.url if !self.medium_id.nil?
      return "#{ROOT_URL.chop}#{cache}_m.jpg" if File.exists?("public#{cache}_m.jpg")
    elsif size =="large"
      return self.cloud_large.url if !self.large_id.nil?
      return "#{ROOT_URL.chop}#{cache}_l.jpg" if File.exists?("public#{cache}_l.jpg")
    elsif size =="large_fb"
      return self.cloud_large_fb.url if !self.large_fb_id.nil?
      return "#{ROOT_URL.chop}#{cache}_f.jpg" if File.exists?("public#{cache}_f.jpg")
    elsif size =="original"
      return self.cloud_original_image.url unless self.cloud_original_image.nil?
      return ROOT_URL+self.original_image_path.gsub(/^public\//,"") if !self.original_image_path.nil? && File.exists?(self.original_image_path)
    end
    raise DBArgumentError
  end

  def fallback
    ##trying to find something decent to show anyways...
    return self.cloud_original_image.url unless self.cloud_original_image.nil?
    return (ROOT_URL+self.original_image_path.gsub(/^public\//,"")) if !self.original_image_path.nil? && File.exists?(self.original_image_path)
    return self.cloud_large.url if !self.large_id.nil?
    return "#{ROOT_URL.chop}#{cache}_l.jpg" if File.exists?("public#{cache}_l.jpg")
    return self.cloud_medium.url if !self.medium_id.nil?
    return "#{ROOT_URL.chop}#{cache}_m.jpg" if File.exists?("public#{cache}_m.jpg")
    return self.cloud_small.url if !self.small_id.nil?
    return "#{ROOT_URL.chop}#{cache}_s.jpg" if File.exists?("public#{cache}_s.jpg")

    return self.url if begin MiniMagick::Image.open(self.url) rescue false end

    ##we can't really answer with a thumbnail... it would suck .. but last resort...
    return self.cloud_thumb.url if !self.thumb_id.nil?
    return "#{ROOT_URL.chop}#{cache}_t.jpg" if File.exists?("public#{cache}_t.jpg")
    return nil
  end


  ## various sizes
  def thumb
    return thumbnail
  end
  def thumbnail
    #resized and cropped to 100x100
    begin
      return get_image "thumb"
    rescue
      return fallback
    end
  end

  def medium
    ## resized to fit within 640x480
    begin
      return get_image "medium"
    rescue
      return fallback
    end
  end

  def large
    ## resized to fit within 640x480
    begin
      return get_image "large"
    rescue
      return fallback
    end
  end

  def small
    ## resized to fit within 640x480
    begin
      return get_image "small"
    rescue
      return fallback
    end
  end

  def large_fb
    begin
      return get_image "large_fb"
    rescue
      return fallback
    end
  end

  def original
    begin
      return get_image "original"
    rescue
      return fallback
    end
  end

  def original_document_url
    if media == "video" then
      return self.cloud_original_video.url unless self.cloud_original_video.nil?
      return ROOT_URL+self.original_video_path.gsub(/^public\//,"") if !self.original_video_path.nil? && File.exists?(self.original_video_path)
      return CloudObject.find(self.webm).url unless self.webm.nil?
      return CloudObject.find(self.mp4).url unless self.mp4.nil?
    end

    return self.original
  end

  def original_document_download_url
    return ROOT_URL+"api/picture/download/#{self.shaken_id}"
  end

  def og_tag
    if !href.nil? && !(matchdata = Picture.check_youtube_url href).nil?
      ##this is a youtube video
      og_tag = "<meta property=\"og:image\" content=\"https://i.ytimg.com/vi/#{matchdata}/maxresdefault.jpg?feature=og\" />"
      og_tag += "\n<meta property=\"og:video\" content=\"https://www.youtube.com/v/#{matchdata}?version=3&amp;autohide=1\" />"
      og_tag += "\n<meta property=\"og:video:type\" content=\"application/x-shockwave-flash\" />"
      og_tag += "\n<meta property=\"og:video:width\" content=\"398\" />"
      og_tag += "\n<meta property=\"og:video:height\" content=\"224\" />"

    elsif !href.nil? && !(matchdata = Picture.check_dailymotion_url href).nil?
      og_tag = "<meta property=\"og:image\" content=\"https://www.dailymotion.com/thumbnail/320x240/video/#{matchdata}\" />"
      og_tag += "\n<meta property=\"og:video\" content=\"https://www.dailymotion.com/swf/video/#{matchdata}?autoPlay=1\" />"
      og_tag += "\n<meta property=\"og:video:type\" content=\"application/x-shockwave-flash\" />"
      og_tag += "\n<meta property=\"og:video:width\" content=\"460\" />"
      og_tag += "\n<meta property=\"og:video:height\" content=\"280\" />"

    elsif !href.nil? && !(matchdata = Picture.check_vimeo_url href).nil?
      og_tag = "<meta property=\"og:image\" content=\"#{self.medium}\"/>"
      og_tag += "\n<meta property=\"og:video\" content=\"https://vimeo.com/moogaloop.swf?clip_id=#{matchdata}&amp;server=vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=1&amp;color=00ADEF&amp;fullscreen=1&amp;autoplay=0&amp;loop=0\" />"
      og_tag += "\n<meta property=\"og:video:type\" content=\"application/x-shockwave-flash\" />"
      og_tag += "\n<meta property=\"og:video:width\" content=\"360\" />"
      og_tag += "\n<meta property=\"og:video:height\" content=\"640\" />"

    elsif !href.nil? && !(matchdata = Picture.check_facebook_url href).nil?
      og_tag = "<meta property=\"og:image\" content=\"#{self.medium}\"/>"
      og_tag += "\n<meta property=\"og:video\" content=\"https://www.facebook.com/v/#{matchdata}\" />"
      og_tag += "\n<meta property=\"og:video:type\" content=\"application/x-shockwave-flash\" />"
      og_tag += "\n<meta property=\"og:video:width\" content=\"460\" />"
      og_tag += "\n<meta property=\"og:video:height\" content=\"280\" />"

    elsif self.media == "video" && self.size > 0 && !( self.webm.nil? && self.mp4.nil? )
      ##it's a local video that works :)
      og_tag = "<meta property=\"og:image\" content=\"#{large_fb}\" />"
      og_tag += "\n<meta property=\"og:video\" content=\"#{ROOT_URL}flash/video-player.swf?url=#{self.video_url[:mp4_permalink]}&autoPlay=true\" />"
      og_tag += "\n<meta property=\"og:video:secure_url\" content=\"#{ROOT_URL.gsub("http:","https:")}flash/video-player.swf?url=#{self.video_url[:mp4_permalink].gsub("http:","https:")}&autoPlay=true\" />"
      og_tag += "\n<meta property=\"og:video:type\" content=\"application/x-shockwave-flash\" />"
      og_tag += "\n<meta property=\"og:video:width\" content=\"460\" />"
      og_tag += "\n<meta property=\"og:video:height\" content=\"280\" />"
    else
      ## by default we treat this as an image and provide with the cached version
      og_tag = "<meta property=\"og:image\" content=\"#{large_fb}\" />"
    end
  end

  ##TODO it should delete existing files and regenerate
  def cache_image destroy_old=false
    require 'open-uri'
    ## WARNING : This will NOT overwrite existsing files
    ##gets a url to a jpeg
    ## create "user_images/image_"+params[:user_id]+"-"+Time.now.strftime("%Y%m%d%H%M%S")+"_s.jpg"
    ## with _s for small image and _m for the bigger version (max 1024 width) returns the name without the _m.jpg or _s.jpg
    start_time = Time.now

    ##try and find a file to process
    if !self.original_image_path.nil? && File.exists?(self.original_image_path)
      ## ideally an original local file
      jpeg = self.original_image_path
    elsif !self.original_image_id.nil?
      ## or an original file stored on the cloud
      jpeg = self.cloud_original_image.url
    elsif !self.url.nil? && begin !MiniMagick::Image.open(self.url.gsub("https\:\/\/", "http\:\/\/")).nil? rescue false end
      ## or a link to the original file after checking that such file still exists
      jpeg = self.url
    elsif !cache.nil? && File.exists?("public#{cache}_l.jpg")
      ## or the large file
      jpeg = "public#{cache}_l.jpg"
    elsif !cache.nil? && File.exists?("public#{cache}_m.jpg")
      ## or the medium file
      jpeg = "public#{cache}_m.jpg"
    else
      #raise DBArgumentError.new "Missing Origin File for #{self.id}"
      return false
    end

    filename = "/user_images/image-cache-#{self.id}"

    logger.debug "thumbnailing image #{filename} from #{jpeg}"
    #open("public"+filename+".jpg", 'wb') do |file|
    #   file << open(jpeg).read
    # end
    begin
      image_path = jpeg.gsub("https\:\/\/", "http\:\/\/")
      image = MiniMagick::Image.open(image_path)
      image.format 'jpg'
      start_time = Time.now
      w, h = image['%w %h'].split
      logger.debug "initial image size #{w} x #{h}"
      initial_surface = w.to_f*h.to_f


      start_time = Time.now
      ## resize to 1280x960
      if w.to_f>h.to_f then
        if w.to_f/12.8>h.to_f/9.6 then
         h = (h.to_f*1280/w.to_f).to_i
         w = 1280
        else
         w = (w.to_f*960/h.to_f).to_i
         h = 960
        end
      else
        if h.to_f/12.8>w.to_f/9.6 then
         w = (w.to_f*1280/h.to_f).to_i
         h = 960
        else
         h = (h.to_f*1280/w.to_f).to_i
         w = 960
        end
      end
      if !File.exists?("public"+filename+"_l.jpg") || destroy_old == true || destroy_old == :large
      ##TODO : delete existing file and regenerate
        if initial_surface < w*h
          image.filter "sinc"
          image.define "filter:support=5"
          image.resize "#{w}x#{h}"
          image.unsharp "0x1"
          logger.debug "using filter sinc"
          image.quality("80%")
        else
          image.resize "#{w}x#{h}"
          logger.debug "downscaling : unsharpen"
          image.quality("83%")
          image.unsharp "3x0.75+0.6+0.03"
        end
        image.strip    # somehow strip removes progressive option, so interlace must be placed just before write
        image.interlace "Line"
        image.write("public"+filename+"_l.jpg")
        logger.debug "Large saved (#{Time.now-start_time}s)"
      end


      image = MiniMagick::Image.open(image_path)
      image.format 'jpg'
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
      if !File.exists?("public"+filename+"_m.jpg") || destroy_old == true || destroy_old == :medium
        image.thumbnail "#{w}x#{h}"
        image.quality("75%")
        image.unsharp "2x0.5+0.6+0.005"
        image.strip    # somehow strip removes progressive option, so interlace must be placed just before write
        image.interlace "Line"
        image.write("public"+filename+"_m.jpg")
        logger.debug "Medium saved (#{Time.now-start_time}s)"
      end


      image = MiniMagick::Image.open(image_path)
      image.format 'jpg'
      start_time = Time.now
      ## resize to 320x240
      w, h = image['%w %h'].split
      if w.to_f>h.to_f then
        if w.to_f/3.2>h.to_f/2.4 then
         h = (h.to_f*320/w.to_f).to_i
         w = 320
        else
         w = (w.to_f*240/h.to_f).to_i
         h = 240
        end
      else
        if h.to_f/3.2>w.to_f/2.4 then
         w = (w.to_f*320/h.to_f).to_i
         h = 240
        else
         h = (h.to_f*320/w.to_f).to_i
         w = 240
        end
      end
      if !File.exists?("public"+filename+"_s.jpg") || destroy_old == true || destroy_old == :small
        image.thumbnail "#{w}x#{h}"
        image.quality("75%")
        image.unsharp "2x0.5+0.6+0.005"
        image.strip
        image.write("public"+filename+"_s.jpg")
        logger.debug "Small saved (#{Time.now-start_time}s)"
      end

      start_time = Time.now

      image = MiniMagick::Image.open(image_path)
      image.format 'jpg'
      ##resize and center the crop
      image.resize "100x100^"
      w, h = image['%w %h'].split
      w = ((w.to_f-100)/2).to_i
      h = ((h.to_f-100)/2).to_i
      if !File.exists?("public"+filename+"_t.jpg") || destroy_old == true || destroy_old == :thumb
        image.crop "100x100+#{w}+#{h}"
        image.quality("75%")
        image.unsharp "2x0.4+0.6+0.002"
        image.strip
        image.write("public"+filename+"_t.jpg")
        logger.debug "thumb saved (#{Time.now-start_time}s)"
      end
      start_time = Time.now


      image = MiniMagick::Image.open(image_path)
      image.format 'jpg'
      ##resize and center the crop
      w, h = image['%w %h'].split

      if w.to_f/56.0 > h.to_f/29.2 then
        image.resize "x627"
      else
        image.resize "1200x"
      end
      w, h = image['%w %h'].split
      w = ((w.to_f-1200)/2).to_i
      h = ((h.to_f-627)/2).to_i
      if !File.exists?("public"+filename+"_f.jpg") || destroy_old == true || destroy_old == :fb
        image.crop "1200x627+#{w}+#{h}"
        image.quality("80%")
        image.unsharp "3x0.75+0.6+0.008"
        image.strip
        image.write("public"+filename+"_f.jpg")
        logger.debug "large_fb saved (#{Time.now-start_time}s)"
      end
      start_time = Time.now



      # Now save on Google storage
      upload_thumbs destroy_old

      rwimage = Picture.find(self.id) ### HACK in case the opbjet is RO ... and we still want to update its params right ??
      rwimage.cache = filename
      rwimage.save!
      self.reload

      return true
    rescue
      ## sth failed....
      logger.debug ENV['PATH']
      logger.debug "FAILED thumbnailing image #{filename} from #{jpeg} : #{$!.message}"
      rwimage = Picture.find(self.id)
      rwimage.cache = nil
      return false
    end
  end
  handle_asynchronously :cache_image

  def video_resize
    if self.media != "video" ## no video to resize (it's an image u see...)
      return false
    end
    if !(Picture.check_youtube_url href).nil? || !(Picture.check_dailymotion_url href).nil?
      ##it's actually an Internet video not a real one handled by diveboard
      return false
    end
    raise DBArgumentError.new "Original video file is missing" if self.original_video_path.nil?

    begin
      webm = Tempfile.new(['video_resize', '.webm'])
      Rails.logger.debug 'Encoding in webm...'
      Rails.logger.debug `ffmpeg -y -i '#{self.original_video_path}' -threads 2 -qmax 63 -ar 22050 -b 600k -ab 64k -vf "scale='min(320, floor(iw*120/ih)*2):min(240, floor(ih*160/iw)*2)'" '#{webm.path}' 2>&1`
      if $?.exitstatus != 0 then
        raise DBArgumentError.new "exit status", status: $?.exitstatus
      end
      webm_co = CloudObject.new(webm.path, :pictures, {:path => self.user_id.to_s, :prefix => "V_#{self.id}_" })
      self.webm = webm_co.id
      webm.delete
    rescue
      Rails.logger.error "Error while converting '#{self.original_video_path}' (#{self.id}) to webm"
    end

    begin
      mp4 = Tempfile.new(['video_resize', '.mp4'])
      Rails.logger.debug 'Encoding in mp4...'
      Rails.logger.debug `ffmpeg -y -i '#{self.original_video_path}' -i_qfactor 0.71 -qcomp 0.6 -qmin 10 -qmax 63 -qdiff 4 -trellis 0 -vcodec libx264 -ar 22050 -b 600k -acodec mp2 -ab 64k -vf "scale='min(320, floor(iw*120/ih)*2):min(240, floor(ih*160/iw)*2)'" '#{mp4.path}' 2>&1`
      mp4_co = CloudObject.new(mp4.path, :pictures, {:path => self.user_id.to_s, :prefix => "V_#{self.id}_" })
      self.mp4 = mp4_co.id
      mp4.delete
    rescue
      Rails.logger.error "Error while converting '#{self.original_video_path}' (#{self.id}) to mp4"
    end

    #self.href = "#{ROOT_URL.chop}/#{self.user.vanity_url}/play_vid/#{self.id}"
    self.save!

  end
  handle_asynchronously :video_resize

  def video_url
    return {
      :thumb_medium => medium,
      :thumb_small => small,
      :thumb_large => large,
      :thumb_large_fb => large_fb,
      :thumb => thumbnail,
      :webm => self.webm && CloudObject.find(self.webm).url,
      :mp4 => self.mp4 && CloudObject.find(self.mp4).url,
      :webm_permalink => begin ROOT_URL+"#{self.user.vanity_url}/videojump/#{self.id}.webm" rescue nil end,
      :mp4_permalink => begin ROOT_URL+"#{self.user.vanity_url}/videojump/#{self.id}.mp4" rescue nil end
    }
  end

  def save_original
    logger.debug "START save_original"
    if !self.original_image_path.nil? && !self.original_image_id.nil?
      if media == "video" && !self.original_image_path.nil? && !self.original_image_id.nil?
        logger.debug "STOP save_original everything is ok video has all the originals already saved"
        return true
      elsif media =="image"
        logger.debug "STOP save_original everything is ok image has all the originals already saved"
        return true
      else

      end
    end

    if !self.original_image_path.nil? || !self.url.nil? || !self.original.nil?
      ## we have some kind of original data ... let's try sth..
      o_image_path = "public/user_images/original-image-#{self.id}"
    else
      o_image_path = nil
    end

    if media == "video"
      if !Picture.check_youtube_url(href).nil? && !Picture.check_dailymotion_url(href).nil?
      ##TODO it's an internet video it will require special treatment one day... until then we just skip
        logger.debug "It's an Internet video - nothing to save yet"
        o_video_path = nil
      end
      if self.original_video_path.nil?
        o_video_path = nil
      else
        o_video_path = "public/user_images/original-video-#{self.id}"
      end
    end

    if o_image_path.nil? && o_video_path.nil?
      logger.debug "STOP save_orignal : nothing to do..."
      return false
    end
    logger.debug "we have image: #{o_image_path} and video #{o_video_path}"
    begin
      if !o_image_path.nil?
         if !self.original_image_path.nil?
           logger.debug "retrieving original from path"
           FileUtils.cp_r self.original_image_path, o_image_path, :remove_destination => true
         elsif !self.url.nil? && begin !(image =  MiniMagick::Image.open(self.url.gsub("https\:\/\/", "http\:\/\/"))).nil? rescue false end
           logger.debug "retrieving original from url"
            FileUtils.cp_r image.path, o_image_path, :remove_destination => true
         elsif !self.cloud_original_image.nil? && !self.cloud_original_image.url.nil?
           logger.debug "retrieving original from cloud"
           FileUtils.cp_r open(self.cloud_original_image.url).path, o_image_path, :remove_destination => true
         else
           logger.debug "no original file found using the fallback"
           FileUtils.cp_r open(self.original).path, o_image_path, :remove_destination => true
         end

        begin
          fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
          content_type = fm.file(o_image_path)
          self.original_content_type = content_type if self.media == 'image'
          ext = Mime::Type.file_extension_of content_type
          if !ext.blank? then
            FileUtils.mv o_image_path, "#{o_image_path}.#{ext}"
            o_image_path = "#{o_image_path}.#{ext}"
          end
        rescue
          Rails.logger.error "Error while adding extension to file #{o_image_path}"
          Rails.logger.debug $!.backtrace.join "\n"
        end

        self.original_image_path = o_image_path
        FileUtils.chmod 0644, o_image_path #fix issues with group not having access to image
        begin
          image = MiniMagick::Image.open(o_image_path)
          self.width, self.height = image['%w %h'].split
        rescue
          Rails.logger.error "Impossible to store the dimensions for #{self.id} : #{$!.message}"
        end

      end
      if !o_video_path.nil?
        FileUtils.cp_r self.original_video_path, o_video_path, :remove_destination => true

        begin
          fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
          content_type = fm.file(o_video_path)
          self.original_content_type = content_type if self.media == 'video'
          ext = Mime::Type.file_extension_of content_type
          if !ext.blank? then
            FileUtils.mv o_video_path, "#{o_video_path}.#{ext}"
            o_video_path = "#{o_video_path}.#{ext}"
          end
        rescue
          Rails.logger.error "Error while adding extension to file #{o_video_path}"
          Rails.logger.debug $!.backtrace.join "\n"
        end

        self.original_video_path = o_video_path
        FileUtils.chmod 0644, o_video_path #fix issues with group not having access to image
      end
      self.save!
      reload
      upload_original
    rescue
      Rails.logger.error "Impossible to store the original media for #{self.id} : #{$!.message}"
    end
  end

  def upload_original
    logger.debug "START upload_original"

    if !self.original_video_path.nil?
      original_video_co = CloudObject.new(self.original_video_path, :originals, {:path => self.user_id.to_s, :prefix => "#{self.id}_video_"})
      self.original_video_id = original_video_co.id
    else
      logger.debug "there's already an original video on the cloud"
    end

    if !self.original_image_path.nil?
      original_image_co = CloudObject.new(self.original_image_path, :originals, {:path => self.user_id.to_s, :prefix => "#{self.id}_image_"})
      self.original_image_id = original_image_co.id
    else
      logger.debug "there's already an original image on the cloud"
    end

    self.save!
    self.reload
    logger.debug "STOP upload_original"
  end
  handle_asynchronously :upload_original

  def upload_thumbs destroy_old=false
    rwimage = Picture.find(self.id) ### HACK in case the opbjet is RO ... and we still want to update its params right ??
    Rails.logger.debug "Starting upload_thumbs for pic #{rwimage.id} @ #{rwimage.cache}"
    return if rwimage.cache.nil?

    begin
      filename = rwimage.cache
      ##SMALL
      if !rwimage.user_id.nil? then
        start_time = Time.now
        if (rwimage.small_id.nil? || destroy_old == true || destroy_old == :small) && File.exists?("public"+filename+"_s.jpg")
          small_co = CloudObject.new("public"+filename+"_s.jpg", :pictures, {:path => rwimage.user_id.to_s, :prefix => "#{rwimage.id}_", :postfix => '_small' })
          if !rwimage.small_id.nil? && destroy_old
            begin
              logger.info "deleting cloud object due to republish (#{rwimage.id}) : #{rwimage.small_id} -> #{small_co.id}"
              CloudObject.find(rwimage.small_id).destroy
            rescue
              logger.warn "error while deleting cloud object #{rwimage.small_id} : #{$!.message}"
            end
          end
          rwimage.small_id = small_co.id
        end
      end

      ##MEDIUM
      if !rwimage.user_id.nil? then
        start_time = Time.now
        if (rwimage.medium_id.nil? || destroy_old == true || destroy_old == :medium)  && File.exists?("public"+filename+"_m.jpg")
          medium_co = CloudObject.new("public"+filename+"_m.jpg", :pictures, {:path => rwimage.user_id.to_s, :prefix => "#{rwimage.id}_", :postfix => '_medium' })
          if !rwimage.medium_id.nil? && destroy_old
            begin
              logger.info "deleting cloud object due to republish (#{rwimage.id}) : #{rwimage.medium_id} -> #{medium_co.id}"
              CloudObject.find(rwimage.medium_id).destroy
            rescue
              logger.warn "error while deleting cloud object #{rwimage.medium_id} : #{$!.message}"
            end
          end
          rwimage.medium_id = medium_co.id
        end
      end

      ##large
      if !rwimage.user_id.nil? then
        start_time = Time.now
        if (rwimage.large_id.nil? || destroy_old == true || destroy_old == :large)  && File.exists?("public"+filename+"_l.jpg")
          large_co = CloudObject.new("public"+filename+"_l.jpg", :pictures, {:path => rwimage.user_id.to_s, :prefix => "#{rwimage.id}_", :postfix => '_large' })
          if !rwimage.large_id.nil? && destroy_old
            begin
              logger.info "deleting cloud object due to republish (#{rwimage.id}) : #{rwimage.large_id} -> #{large_co.id}"
              CloudObject.find(rwimage.large_id).destroy
            rescue
              logger.warn "error while deleting cloud object #{rwimage.large_id} : #{$!.message}"
            end
          end
          rwimage.large_id = large_co.id
        end
      end

      ##large fb
      if !rwimage.user_id.nil? then
        start_time = Time.now
        if (rwimage.large_fb_id.nil? || destroy_old == true || destroy_old == :fb)  && File.exists?("public"+filename+"_f.jpg")
          large_fb_co = CloudObject.new("public"+filename+"_f.jpg", :pictures, {:path => rwimage.user_id.to_s, :prefix => "#{rwimage.id}_", :postfix => '_large_fb' })
          if !rwimage.large_fb_id.nil? && destroy_old
            begin
              logger.info "deleting cloud object due to republish (#{rwimage.id}) : #{rwimage.large_fb_id} -> #{large_fb_co.id}"
              CloudObject.find(rwimage.large_fb_id).destroy
            rescue
              logger.warn "error while deleting cloud object #{rwimage.large_fb_id} : #{$!.message}"
            end
          end
          rwimage.large_fb_id = large_fb_co.id
        end
      end

      ##thumb
      if !rwimage.user_id.nil? then
        start_time = Time.now
        if (rwimage.thumb_id.nil? || destroy_old == true || destroy_old == :thumb) && File.exists?("public"+filename+"_t.jpg")
          thumb_co = CloudObject.new("public"+filename+"_t.jpg", :pictures, {:path => rwimage.user_id.to_s, :prefix => "#{rwimage.id}_", :postfix => '_thumb' })
          if !rwimage.thumb_id.nil? && destroy_old
            begin
              logger.info "deleting cloud object due to republish (#{rwimage.id}) : #{rwimage.thumb_id} -> #{thumb_co.id}"
              CloudObject.find(rwimage.thumb_id).destroy
            rescue
              logger.warn "error while deleting cloud object #{rwimage.thumb_id} : #{$!.message}"
            end
          end
          rwimage.thumb_id = thumb_co.id
        end
      end


      rwimage.save!
      logger.debug "End of picture upload to cloud (#{rwimage.id} ; #{Time.now-start_time}s)"
    rescue
      Rails.logger.warn "Error while uploading the thumbs to Google for pic #{rwimage.id}: #{$!.message}"
      Rails.logger.debug $!.backtrace.join "\n"
      small_co.destroy unless small_co.nil?
      medium_co.destroy unless medium_co.nil?
      large_co.destroy unless large_co.nil?
      large_fb_co.destroy unless large_fb_co.nil?
      thumb_co.destroy unless thumb_co.nil?
    end

  end
  handle_asynchronously :upload_thumbs

  def destroy_thumbs
    ##destroys the thumbs before destorying the image
    if !cache.nil?
      if File.exists?("public#{cache}_m.jpg")
        File.delete("public#{cache}_m.jpg")
      end
      if File.exists?("public#{cache}_s.jpg")
        File.delete("public#{cache}_s.jpg")
      end
      if File.exists?("public#{cache}_t.jpg")
        File.delete("public#{cache}_t.jpg")
      end
      if File.exists?("public#{cache}_l.jpg")
        File.delete("public#{cache}_l.jpg")
      end
    end
    [self.small_id, self.medium_id, self.large_id, self.large_fb_id, self.thumb_id, self.webm, self.mp4].each do |co_id|
      if !co_id.nil? then
        begin
          co = CloudObject.find(co_id)
          co.destroy unless co.nil?
        rescue
        end
      end
    end
    self.small_id = nil
    self.medium_id = nil
    self.large_id = nil
    self.large_fb_id = nil
    self.thumb_id
    self.cache = nil
    self.webm = nil
    self.mp4 = nil
    save!
  end

  def destroy
    PictureAlbumPicture.where(:picture_id => self.id).destroy_all
  end

  def regenerate! destroy_old=true
    previous_val = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    self.cache_image destroy_old ##will recreate the thumbs and re-upload

    if self.media == "video" && Picture.check_youtube_url(href).nil? && Picture.check_dailymotion_url(href).nil? && Picture.check_vimeo_url(href).nil? && Picture.check_facebook_url(href).nil? then
      #this may be a real video
      self.video_resize
    end

    Delayed::Worker.delay_jobs = previous_val
  end


  def fullpermalink user_hint = nil, options=nil
    ## identify where it's being used
    Rails.logger.warn "There may be an issue with parameters to fullpermalink for picture here" if options.nil? && !user_hint.is_a?(User)
    begin
      return "#{user_hint.fullpermalink(options)}/pictures/#{self.id}" if user_hint.is_a?(User)
      if !dive.nil?
        return "#{dive.user.fullpermalink(options)}/pictures/#{self.id}"
      elsif !blogpost.nil?
        return blogpost.fullpermalink(options)
      else
        raise DBArgumentError.new "No link for this picture"
      end
    rescue
      return "#"
    end
  end

  def permalink user_hint = nil
    ## identify where it's being used
    begin
      return "#{user_hint.permalink}/pictures/#{self.id}" unless user_hint.nil?
      if !dive.nil?
        return "#{dive.user.permalink}/pictures/#{self.id}"
      elsif !blogpost.nil?
        return blogpost.permalink
      else
        raise DBArgumentError.new "No link for this picture"
      end
    rescue
      return "#"
    end
  end

  def fulltinylink
    begin
      return ROOT_TINY_URL+"p/#{self.id}"
    rescue
      return nil
    end
  end

  def to_hash
    #               pictures => [{id, title, species=>[{sname, cname, id (s- or c-)},{}... ]}, url, origin_url]
    hash = {}
    hash[:id] = self.id
    hash[:title] = self.notes
    hash[:url_medium] = self.medium
    hash[:url_small] = self.small
    hash[:url_large] = self.large
    hash[:url_large_fb] = self.large_fb
    hash[:url_thumb] = self.thumbnail
    hash[:origin_url] = self.original
    hash[:species] = []
    self.eolcnames.each do |fish|
      hash[:species] << fish.to_hash
    end
    self.eolsnames.each do |fish|
      hash[:species] << fish.to_hash
    end
    return hash

  end

  def cloud_objects
    objects = {}
    objects[:original_image] = self.cloud_original_image unless self.original_image_id.nil?
    objects[:original_video] = self.cloud_original_video unless self.original_video_id.nil?
    objects[:large] = self.cloud_large_id unless self.large_id.nil?
    objects[:large_fb] = self.cloud_large_fb_id unless self.large_fb_id.nil?
    objects[:medium] = self.cloud_medium_id unless self.medium_id.nil?
    objects[:small] = self.cloud_small_id unless self.small_id.nil?
    objects[:thumb] = self.cloud_thumb_id unless self.thumb_id.nil?
    objects[:webm] = self.cloud_webm unless self.webm.nil?
    objects[:mp4] = self.cloud_mp4 unless self.mp4.nil?
    return objects
  end

  def self.orphans
    Picture.select('pictures.id').joins("LEFT JOIN picture_album_pictures ON picture_album_pictures.picture_id = pictures.id").where("picture_album_pictures.picture_id is null").map {|p| Picture.find(p.id)}
  end


  def exif_data
    begin
      if exif.nil?
        Rails.logger.warn "EXIF data recalculated for picture #{self.id}"
        Rails.logger.debug caller.join "\n"
        self.get_exif_data
        return {}
      else
        return JSON.parse(exif)
      end
    rescue
      Rails.logger.warn "EXIF data recalculated for picture #{self.id}: #{$!.message}"
      Rails.logger.debug $!.backtrace.join "\n"
      self.get_exif_data
      return {}
    end
  end

  def useful_exif_data
    data = exif_data
    useful_data = {}
    keys = %w{Make Model ExposureTime Flash Lens MaxApertureValue FNumber ExposureTime ISO}
    keys.each do |key|
      useful_data[key] = data[key]
    end
    return useful_data
  end

  def player width=nil, height=nil
    ##we set defaults
    if width.nil? then width = 640 end
    if height.nil? then height = 360 end

    if self.media == "video"
      if !href.nil? && !(matchdata = Picture.check_youtube_url href).nil?
        ##this is a youtube video
        return code = "<iframe width='#{width}' height='#{height}' src='https://www.youtube.com/embed/#{matchdata}?wmode=opaque&autoplay=0' frameborder='0' allowfullscreen></iframe>"
      elsif !href.nil? && !(matchdata = Picture.check_dailymotion_url href).nil?
        ##dailymotion video
        return code = "<iframe frameborder='0' width='#{width}' height='#{height}' src='https://www.dailymotion.com/embed/video/#{matchdata}?autoplay=1'></iframe>"
      elsif !href.nil? && !(matchdata = Picture.check_vimeo_url href).nil?
        return code = "<iframe src='https://player.vimeo.com/video/#{matchdata}' width='#{width}' height='#{height}' frameborder='0' webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"
      elsif !href.nil? && !(matchdata = Picture.check_facebook_url href).nil?
        code ="<iframe width='#{width}' height='#{height}' src='/api/fbvideo_proxy?id=#{matchdata}&width=#{width}&height=#{height}' frameborder='0'></iframe>"
        return code
      elsif self.media == "video" && self.size > 0 && !self.video_url[:mp4].nil? && !self.video_url[:webm].nil?
        ##local video with local player
         code =  "<video width='#{width}' height='#{height}' poster='#{self.medium}' controls='controls' preload='none'>"
         code += "<source type='video/webm' src='#{self.video_url[:webm]}' />"
         code += "<source type='video/mp4' src='#{self.video_url[:mp4]}' />"
         code += "<object width='#{width}' height='#{height}' type='application/x-shockwave-flash' data='/img/mediaelement/flashmediaelement.swf'>"
                 code += "<param name='movie' value='/img/mediaelement/flashmediaelement.swf' />"
                 code += "<param name='flashvars' value='controls=true&file=#{self.video_url[:mp4]}' />"
                 code += "<img src='#{self.medium}' width='#{width}' height='#{height}' title='"+It.it("No video playback capabilities", scope:['model', 'picture'])+"' />"
             code += "</object>"
         code += "</video>"
         return code
      else
      ##TODO still processing
      code =  "<img width='#{width}' height='#{height}' src='/img/video_being_processed.png' controls='controls' preload='none'>"
      code += "</img>"
      return code
      return nil
      end
      return nil
    else
      return nil
    end

  end

  def self.check_youtube_url addr
    begin
      if (m= addr.match(/youtube\.com.*v=([a-zA-Z0-9\_\-]*)/))
        return m[1]
      elsif (m= addr.match(/youtube\.com\/embed\/([a-zA-Z0-9\_\-]*)/))
        return m[1]
      elsif (m = url.match(/^.*youtube\.com\/.*\/([a-zA-Z0-9\-\_]*)$/i))
        return m[1]
      elsif (m = url.match(/^.*youtu\.be\/([a-zA-Z0-9\-\_]*)$/i))
        return m[1]
      else
        return nil
      end
    rescue
      nil
    end
  end

  def self.generate_youtube_thumb id
    return "http://img.youtube.com/vi/#{id.to_s}/default.jpg"
    begin
      return JSON.parse(Net::HTTP.get URI.parse(jsoncall))["thumbnail_url"]
    rescue
      return nil
    end
  end

  def self.check_dailymotion_url addr
    begin
      if (r =addr.match(/dailymotion\.com\/video\/([a-zA-Z0-9]+)\_*/))
        return r[1]
      elsif (r =addr.match(/dailymotion\.com\/swf\/video\/([a-zA-Z0-9]+)\_*/))
        return r[1]
      else
        raise DBArgumentError.new "Not a dailymotion url"
      end
    rescue
      nil
    end
  end

  def self.generate_dailymotion_thumb id
    jsoncall = "http://www.dailymotion.com/services/oembed?format=json&url=http%3A//www.dailymotion.com/video/#{id.to_s}"
    begin
      response = JSON.parse(Net::HTTP.get URI.parse(jsoncall))
      if response.class == Array
        response = response[0]
      end
      return response["thumbnail_url"]
    rescue
      return nil
    end
  end

  def self.check_vimeo_url addr
    begin
      addr = addr.split("?")[0] # remove args
      return addr.match(/vimeo\.com\/[video\/]*([0-9]+)$/)[1]
    rescue
      nil
    end
  end

  def self.generate_vimeo_thumb id
    jsoncall = "http://vimeo.com/api/v2/video/#{id.to_s}.json"
    begin
      return JSON.parse(Net::HTTP.get URI.parse(jsoncall))[0]["thumbnail_large"]
    rescue
      return nil
    end
  end

  def self.check_facebook_url addr
    begin
      if r=addr.match(/^.*facebook.com\/.+\?.*v=([0-9]*).*$/)
        return r[1]
      elsif r=addr.match(/^.*facebook.com\/v\/([0-9]*).*$/)
        return r[1]
      else
        raise DBArgumentError.new "Not a facebook video"
      end
    rescue
      nil
    end
  end

  def self.generate_facebook_thumb id, user=nil
    begin
      logger.debug "requesting /#{id}?token=#{user.fbtoken}"
      graph = Koala::Facebook::API.new(user.fbtoken)
      result = graph.get_object("#{id}")
      return result["picture"]
    rescue
      return nil
    end
  end


  def self.thumb_from_video video_url, user=nil
    #gives a url to a thumbnail for a video url
    if (id =Picture.check_youtube_url(video_url))
      return  Picture.generate_youtube_thumb(id)
    elsif (id =Picture.check_dailymotion_url(video_url))
      return  Picture.generate_dailymotion_thumb(id)
    elsif (id =Picture.check_vimeo_url(video_url))
      return Picture.generate_vimeo_thumb(id)
    elsif (id =Picture.check_facebook_url(video_url))
      return Picture.generate_facebook_thumb(id, user)
    else
      return nil
    end
  end


  def species
    ##will return an array of species { :name => "", :link => "", :sci_name => ""}
    ## asselbles the eolcnames and eolsnames from a given dive
    ## for eolsnames name == sci_name

    eols = self.eolsnames
    eolc = self.eolcnames
    result = []
    eolc.each do |species|
      result << {:id => "c-#{species.id}", :name => species.cname, :sname => species.eolsname.sname, :link => species.eolsname.url, :thumbnail_href => species.eolsname.thumbnail_href, :picture => species.eolsname.picture}
    end
    eols.each do |species|
      result << {:id => "s-#{species.id}", :name => species.sname, :sname => species.sname, :link => species.url, :thumbnail_href => species.thumbnail_href, :picture => species.picture}
    end
    return result
  end

  def species=(fish_list)
    fish_list = [] if fish_list.nil?
    dive_cnames = []
    dive_snames = []
    fish_list.each do |fish|
      fishid = fish[:id] || fish['id'] rescue nil
      raise DBArgumentError.new "Species id not valid", in: fish.to_s if fishid.nil?
      logger.debug "Adding species id: #{fishid}"
      if  !(fishnum = fishid.match(/^c-([0-9]*)$/)).nil?
        dive_cnames << Eolcname.find(fishnum[1])
      elsif  !(fishnum = fishid.match(/^s-([0-9]*)$/)).nil?
        dive_snames << Eolsname.find(fishnum[1])
      else
        raise DBArgumentError.new "id not valid for fish", id: fishid
      end
    end
    self.eolcnames = dive_cnames
    self.eolsnames = dive_snames
  end

  def shaken_id
    "P#{Mp.shake(self.id)}"
  end

  def self.idfromshake code
    if code[0] == "P"
       i =  Mp.deshake(code[1..-1])
    else
       i = code.to_i
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      return (Picture.find(i)).id
    end
  end

  def self.fromshake code
    if code[0] == "P"
       i =  Mp.deshake(code[1..-1])
    else
       i = code.to_i
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      return Picture.find(i)
    end
  end

  def redirect_link
    "/api/picture/get/#{shaken_id}"
  end

  def full_redirect_link
    ROOT_URL.chop+redirect_link
  end

  def append_to_album album_id
    PictureAlbumPicture.create :picture_album_id => album_id, :picture_id => self.id
  end

  def cropable
    begin
      if self.original_content_type.nil? then
        fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
        if media=='image' && File.exists?(self.original_image_path) then
          self.original_content_type = fm.file(self.original_image_path)
        elsif media=='video' && File.exists?(self.original_video_path) then
          self.original_content_type = fm.file(self.original_video_path)
        else
          io = open(self.original_document_url)
          tmp_file = Tempfile.new('original_mime_migration')
          tmp_file.binmode
          tmp_file.write io.read
          tmp_file.flush
          self.original_content_type = fm.file(tmp_file.path)
          tmp_file.close
          tmp_file.delete
        end
        self.save!
      end
      return !self.original_content_type.match(/image/).nil?
    rescue
      Rails.logger.warn "Problem while checking if picture is cropable : #{$!.message}"
      Rails.logger.debug $!.backtrace.join("\n")
      return false
    end
  end


  def update_fb_comments
    ## will grab the FB comment of the dive and save it
    ## dive comment link : http://www.diveboard.com/ksso/D25AZIW
    require 'curb'
    comment_link = self.fullpermalink(:canonical)
    fburl = "http://graph.facebook.com/v2.0/comments?id=#{comment_link}"
    res = Curl.get(fburl)
    if res.response_code == 200
      FbComments.update_fb_comments self, res.body_str
    end
  end
  handle_asynchronously :update_fb_comments

  def update_fb_like
    FbLike.get self unless self.fullpermalink(:canonical) == '#'
  end
  handle_asynchronously :update_fb_like



  def publish_to_fb_page
    #Since it's workign asynchronously, we'll let it fail vocally ;)
    return :not_dive_picture if self.dive.nil?
    return :already_published unless self.fb_graph_id.nil?
    pageowner = User.find(30) ## alex owns the diveboard FB page (so 30 being hardcoded makes somehow sense)
    graph = Koala::Facebook::API.new(pageowner.fbtoken)
    accounts = graph.get_connections('me', 'accounts')
    accounts.reject!{|e| e["id"]!="140880105947100"} ## getting the data about the Diveboard page
    page_token = accounts[0]["access_token"] ## getting a token to act as page
    page_access = Koala::Facebook::API.new(page_token)
    message = "#{self.fullpermalink(:canonical)}\nTaken by #{self.user.nickname} in #{begin self.dive.spot.name rescue "an unknown place" end}, #{ begin self.dive.spot.country.cname rescue "" end} on #{self.dive.time_in.strftime("%b %e %Y")}"
    picpath = MiniMagick::Image.open(self.large).path
    Rails.logger.debug "Got image on path #{picpath}"
    pic = Koala::UploadableIO.new(picpath)
    data = {:message => message, :link => self.fullpermalink(:canonical)}
    Rails.logger.debug "Publising to FB Diveboard page the picture #{self.id}, url #{self.large}, data #{data}"
    #a.555374081164365.1073741825.140880105947100 << album id on FB
    result = page_access.put_picture picpath, data, 555374081164365
    self.fb_graph_id = result
    self.save!
    return result
  end
  handle_asynchronously :publish_to_fb_page


  def publish_to_fb_as_link
    pageowner = User.find(30) ## alex owns the diveboard FB page (so 30 being hardcoded makes somehow sense)
    graph = Koala::Facebook::API.new(pageowner.fbtoken)
    accounts = graph.get_connections('me', 'accounts')
    accounts.reject!{|e| e["id"]!="140880105947100"} ## getting the data about the Diveboard page
    page_token = accounts[0]["access_token"] ## getting a token to act as page
    page_access = Koala::Facebook::API.new(page_token)

    dive = self.dive
    return if dive.nil?
    result = page_access.put_object(
      140880105947100,
      "feed",
      :name => "#{dive.spot.name}, #{dive.spot.country.name}",
      :caption => "by #{dive.user.nickname}",
      :description => "Great pictures uploaded by divers on Diveboard, hand picked every day.",
      :link => self.fullpermalink(:canonical),
      :picture => self.large_fb
      )
    self.fb_graph_id = result
    self.save!
    return result
  end

  def elligible_best_pic
    return width && height && width >= height
  end

  def self.find_pic min_ratio, max_ratio
    Picture.where("(width / height) BETWEEN ? AND ?", min_ratio, max_ratio)
  end

  def self.find_best_pic min_ratio, max_ratio
    self.find_pic(min_ratio, max_ratio).where("great_pic = true")
  end
end
