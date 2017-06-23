class AddVideoToPictures < ActiveRecord::Migration
  def self.up
    begin
      remove_column :pictures, :original_path
      remove_column :pictures, :media
      remove_column :pictures, :webm
      remove_column :pictures, :mp4
    rescue 
    end
    add_column :pictures, :original_path, :text
    add_column :pictures, :media, "ENUM('image', 'video')", :null => false, :default => 'image'
    add_column :pictures, :webm, :integer
    add_column :pictures, :mp4, :integer
    Picture.all.each do |pic|
      if pic.href.match(/youtube\.com.*v=([a-zA-Z0-9]*)/) || pic.href.match(/dailymotion\.com\/video\/([a-zA-Z0-9]*)\_/) then
        pic.media = 'video' 
        pic.save!
      end
    end
  end

  def self.down
    remove_column :pictures, :original_path
    remove_column :pictures, :webm
    remove_column :pictures, :mp4
    remove_column :pictures, :media
  end
end
