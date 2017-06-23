class AddGalleryAndCoverToAlbumsEnum < ActiveRecord::Migration
  def up
    change_column :albums, :kind, "ENUM('dive', 'wallet', 'trip', 'blog', 'shop_ads', 'avatar', 'shop_cover', 'shop_gallery')", :null => false
  end

  def down
    change_column :albums, :kind, "ENUM('dive', 'wallet', 'trip', 'blog', 'shop_ads', 'avatar')", :null => false
  end
end
