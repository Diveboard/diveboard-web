class AddMisc2Indexes < ActiveRecord::Migration
  def self.up
    add_index :blog_posts, [:published, :published_at]
    add_index :payments, [:user_id, :status]
    add_index :picture_album_pictures, [:picture_album_id, :ordnum, :picture_id], :name => :picture_album_pictures_on_album
  end

  def self.down
    remove_index :blog_posts, [:published, :published_at]
    remove_index :payments, [:user_id, :status]
    remove_index :picture_album_pictures, :name => :picture_album_pictures_on_album
  end
end
