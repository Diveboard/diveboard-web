class AddIndexOnNewTable < ActiveRecord::Migration
  def up
    add_index :areas, [:minlat, :maxlat, :minlng, :maxlng, :active], name: "index_areas_on_coordinate_and_active"
    add_index :areas, :geonames_core_id
    add_index :areas, :url_name

    add_index :area_categories, :area_id
    add_index :area_categories, [:category, :count]

    remove_index :shop_details, :shop_id
    add_index :shop_details, [:shop_id, :kind]
  end

  def down
  end
end
