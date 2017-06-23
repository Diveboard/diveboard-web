require 'delayed_job'
require 'nokogiri'

class Wiki < ActiveRecord::Base
  belongs_to :user
  has_many :picture_album_pictures, :primary_key => 'album_id', :foreign_key => 'picture_album_id', :include => [:picture]
  belongs_to :source, :polymorphic => true
  default_scope order("wikis.updated_at desc")

  #Wiki page
  # points to an object identified by
  # source_type => "Spot" "Country" ...  WATCH OUT enum in db must be updated for new types
  # source_id => the id in base
  # user_id => who created the entry
  # verified_user_id => set to the user who verified it

  #latest entry for an object is the last one that was validated

  ## This is the proper way of getting a Wiki object - koz u're not supposed to know its id


  def is_private_for?(options={})
    return false if options[:caller].nil?
    return true if options[:action] == :create
    return true if options[:caller].admin_rights > 2
    return true if options[:caller].id == self.user_id
    return false
  end




  def self.get_wiki type, id, userid=nil
    Rails.logger.debug "Getting wiki entry #{id.to_s} of type #{type.to_s.titleize} for user #{userid.to_s}"
    entries = Wiki.where(:source_type => type, :source_id => id).where("verified_user_id is not null")
    if !userid.nil?
      entries.push(Wiki.where(:source_type => type, :source_id => id, :user_id => userid)).flatten!.uniq!
    end
    Rails.logger.debug "Found entriel #{(entries.map &:id).to_json}"
    entries.sort! {|i,j|
          i.updated_at <=> j.updated_at || i.id <=> j.id
      }
    if entries.empty?
      return nil
    else
      return entries.last
    end
  end

  #creates a new wiki entry
  def self.create_wiki type, id, text, userid=nil
    if type.class != String
      type = type.class.to_s
    end
    w = Wiki.new
    w.source_id = id.to_i
    w.source_type = type.to_s
    w.data = text.to_s
    w.user_id = userid
    w.save!
    return w
  end


  def pictures
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture).to_ary
  end

  def pictures=(added_pictures)
    if self.album_id.nil? then
      album = Album.create :user_id => self.user_id, :kind => 'blog'
      self.album_id = album.id
    end
    Picture.transaction {
      self.class.connection.execute("DELETE FROM picture_album_pictures WHERE picture_album_id = #{self.album_id}")
      args = []
      added_pictures.each do |pic|
        pic.save if pic.new_record?
        args.push "(#{self.album_id}, #{pic.id})"
      end
      self.class.connection.execute("INSERT INTO picture_album_pictures (picture_album_id, picture_id) VALUES #{ args.join(',') }") unless args.count == 0
    }
    return added_pictures
  end

  def extract_pics_from_text
    begin
      ##this gets all img linked to from text
      ## this adds them to album if they're external
      ## this replace with url to "original"

      ## this also looks for iframe from youtube/vimeo/


      pics = []
      new_pics = []
      doc = Nokogiri::HTML(self.data.html_safe)


      ## STEP 1 : PICTURES

      doc.css('img').each do |node|
        Rails.logger.debug "Checking node #{node.to_s}"
        begin
          img_url = node.attributes["src"].value
          ##check if it's a diveboard image
          if (sid=img_url.match(/\/api\/picture\/get\/([a-zA-Z0-9]+)/))
            #existing picture
            begin
              pics << Picture.fromshake(sid[1])
            rescue
              Rails.logger.warn "wiki mentions Picture #{sid[1]} which could not be found"
            end
          else
            begin
              new_picture = Picture.create_image :url => img_url, :user_id => self.user_id
              pics << new_picture
              new_pics << new_picture ## we'll need to do the gsub dance
            rescue
              Rails.logger.warn "Wiki mentions image with url #{img_url} which came back invalid"
            end
          end
        rescue
          Rails.logger.warn "Could not analyze node #{node.to_json}"
        end
      end


      ## STEP2 : VIDEOS

      doc.css('iframe').each do |node|
        Rails.logger.debug "Checking node #{node.to_s}"
        begin
          video_url = node.attributes["src"].value
          cached_thumb =  begin node.attributes["divbeoard_thumb"].value rescue "" end
          ##check if it's a diveboard image
          if (sid=cached_thumb.match(/\/api\/picture\/get\/([a-zA-Z0-9]+)/))
            #existing picture
            begin
              pics << Picture.fromshake(sid[1])
            rescue
              Rails.logger.warn "wiki mentions Picture #{sid[1]} which could not be found"
            end
          else
            begin

              raise DBArgumentError.new "not a video" if (thumb_url = Picture.thumb_from_video(video_url)).nil?

              new_picture = Picture.create_image :url => thumb_url, :user_id => self.user_id
              pics << new_picture
              new_pics << new_picture ## we'll need to do the gsub dance
              node["divbeoard_thumb"] = new_picture.full_redirect_link ##update with the full redirect link
            rescue
              Rails.logger.warn "Wiki mentions image with url #{img_url} which came back invalid"
            end
          end
        rescue
          Rails.logger.warn "Could not analyze node #{node.to_json}"
        end
      end


      ## STEP3 :  time to save
      text = doc.at_css("body").inner_html ## we get the modified dom (video with appended tag)
      new_pics.each do |p|
        text = text.gsub(p.url, "#{p.full_redirect_link}/original") ## update links (images)
      end

      self.data = text
      self.pictures = pics
      self.save
    rescue
      Rails.logger.debug $!.message
      if data.blank?
        Rails.logger.warn "Wiki has no avilable text"
      else
        Rails.logger.warn "Could not extract pics from wiki text #{self.id}"
      end
    end
  end

  def html
    self.data.html_safe
  end

  def shaken_id
    "W#{Mp.shake(self.id)}"
  end

   def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "W"
       i =  Mp.deshake(code[1..-1])
    else
       i = code.to_i
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      return i
    end
  end
end
