require 'fileutils'
class AddStatusToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :thumb_id, :integer rescue nil
    add_column :pictures, :large_id, :integer rescue nil
    add_column :pictures, :original_image_path, :string rescue nil
    add_column :pictures, :original_video_path, :string rescue nil
    add_column :pictures, :original_image_id, :integer rescue nil
    add_column :pictures, :original_video_id, :integer rescue nil
    remove_column :pictures, :name rescue nil
    remove_column :pictures, :service rescue nil
    remove_column :pictures, :dive_id rescue nil
    remove_column :pictures, :tags rescue nil
    remove_column :pictures, :featured rescue nil
    # allow null on column "url"
    execute "ALTER TABLE pictures MODIFY url VARCHAR(255)"
        
    Picture.all.each{|p| 
        ##smalls are actually thumbs....
        p.thumb_id = p.small_id
        p.small_id = nil
        
        ### moving original_path where it belong in cases image or video
        if !p.original_path.nil?
          if p.media == "image"
            p.original_image_path = p.original_path
            p.original_image_id = p.original_id
          elsif p.media == "video"
            p.original_video_path = p.original_path
            p.original_video_id = p.original_id
          end
        end
        if p.media =="video" && (Picture.check_youtube_url p.href).nil? && (Picture.check_dailymotion_url p.href).nil?
          #it's not an internet video => it has been uploaded directly and does not need an href
          p.href= nil
        end
        

        ## in the video case we may have the original video thumbnail to move as original image
        if !p.url.nil? && matchdata = p.url.match(/^.*diveboard\.com(.*\/video\_.*\_marked\.jpg)$/i)
          p.original_image_path = "public"+matchdata[1].gsub(/\/\//,"/")
          p.url = nil
        end
        
        if !p.url.nil? && p.url.match(/diveboard\.com/)
          #most of the urls are bogus when they link to diveboard which is silly anyways
          p.url = nil
        end
        
        if !p.href.nil? && (!p.href.split("?")[0].match(/\.jpg$/i).nil? || !p.href.split("?")[0].match(/\.png$/i).nil?)
          ##this is not a href, it's a url...
          if p.url.nil?
            p.url = p.href
          end
          p.href = nil
        end
        
        ## move  thumb file nicely with the proper name
        if !p.cache.nil? && (File.exists? "public#{p.cache}_s.jpg")
          FileUtils.mv("public#{p.cache}_s.jpg", "public#{p.cache}_t.jpg")
        end
        
        ##save the mess
        begin p.save! rescue puts "could not save id #{p.id}" end
        ##p.cache_image will be done later manually to prevent too long migration 
        ##p.cache_image
        
        
      }
      
    
    remove_column :pictures, :original_path
    remove_column :pictures, :original_id
    puts "you must now execute in console: \n Picture.all.each{|p| p.save_original(); p.get_exif_data(); p.cache_image(); p.update_size(); puts(\"\\r\#{p.id}\"); sleep(1);}"
    
      
  end

  def self.down
  end
end
