class RenameAlbumCertifToWallet < ActiveRecord::Migration
  def self.up
    change_column :albums, :kind, "ENUM('dive', 'wallet', 'trip', 'blog', 'shop_ads')", :null => false
  end

  def self.down
    change_column :albums, :kind, "ENUM('dive', 'certif', 'trip', 'blog', 'shop_ads')", :null => false
  end
end
