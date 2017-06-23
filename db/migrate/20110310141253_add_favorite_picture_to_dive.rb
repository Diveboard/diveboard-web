class AddFavoritePictureToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :favorite_picture, :integer
  end

  def self.down
    remove_column :dives, :favorite_picture
  end
end
