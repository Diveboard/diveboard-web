class AddIndexPictureOnAlbum < ActiveRecord::Migration
  def self.up
    add_index :picture_album_pictures, :picture_id
  end

  def self.down
    remove_index :picture_album_pictures, :picture_id
  end
end
