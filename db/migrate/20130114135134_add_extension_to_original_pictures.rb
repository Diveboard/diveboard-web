require 'filemagic'
require 'open-uri'

class AddExtensionToOriginalPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :original_content_type, :string rescue puts "Column original_content_type already there: skipping"

    fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)

    Picture.where(:original_content_type => nil).each do |pic|
      begin
        # store original_content_type exists
        if pic.media == "video" && !pic.original_video_path.nil? && File.exists?(pic.original_video_path) then
          pic.original_content_type = fm.file(pic.original_video_path)

        elsif pic.media == "video" && !pic.cloud_original_video.nil? then
          io = open(pic.cloud_original_video.url)
          tmp_file = Tempfile.new('original_mime_migration')
          tmp_file.binmode
          tmp_file.write io.read
          tmp_file.flush
          pic.original_content_type = fm.file(tmp_file.path)
          tmp_file.close
          tmp_file.delete

        elsif pic.media == "image" && File.exists?(pic.original_image_path) then
          pic.original_content_type = fm.file(pic.original_image_path)

        elsif pic.media == "image" then
          io = open(pic.original)
          tmp_file = Tempfile.new('original_mime_migration')
          tmp_file.binmode
          tmp_file.write io.read
          tmp_file.flush
          pic.original_content_type = fm.file(tmp_file.path)
          tmp_file.close
          tmp_file.delete
        end

        next if pic.original_content_type.blank?
        pic.save!

        #rename the local file, if any, and update the DB accordinly
        if pic.media == "video" && !pic.original_video_path.nil? && File.exists?(pic.original_video_path) then
          ext = Mime::Type.file_extension_of pic.original_content_type
          if !ext.blank? then
            FileUtils.mv pic.original_video_path, "#{pic.original_video_path}.#{ext}"
            pic.original_video_path = "#{pic.original_video_path}.#{ext}"
            pic.save!
          end

        elsif pic.media == "image" && File.exists?(pic.original_image_path) then
          ext = Mime::Type.file_extension_of pic.original_content_type
          if !ext.blank? then
            FileUtils.mv pic.original_image_path, "#{pic.original_image_path}.#{ext}"
            pic.original_image_path = "#{pic.original_image_path}.#{ext}"
            pic.save!
          end
        end

      rescue
        puts "Error while working on picture #{pic.id} : #{$!.message}"
        Rails.logger.warn "Error while working on picture #{pic.id} : #{$!.message}"
        Rails.logger.debug $!.backtrace.join "\n"
      end

    end
  end

  def self.down
    remove_column :pictures, :original_content_type
  end
end
