class AddExifDataToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :exif, :longtext
  end

  def self.down
    remove_column :pictures, :exif
  end
end
