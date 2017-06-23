class AddAdvertAlbumType < ActiveRecord::Migration
  def self.up
    change_column :albums, :kind, "ENUM('dive', 'certif', 'trip', 'blog', 'shop_ads')", :null => false
  end

  def self.down
    change_column :albums, :kind, "ENUM('dive', 'certif', 'trip', 'blog')", :null => false
  end
end
