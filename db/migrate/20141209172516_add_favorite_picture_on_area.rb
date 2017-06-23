class AddFavoritePictureOnArea < ActiveRecord::Migration
  def up
    add_column :areas, :favorite_picture_id, :integer
  end

  def down
    remove_column :areas, :favorite_picture_id
  end
end
