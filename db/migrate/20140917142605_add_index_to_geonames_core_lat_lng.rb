class AddIndexToGeonamesCoreLatLng < ActiveRecord::Migration
  def up
  	add_index :geonames_cores, :latitude
  	add_index :geonames_cores, :longitude
  end

  def down
  	remove_index :geonames_cores, :latitude
  	remove_index :geonames_cores, :longitude
  end
end
