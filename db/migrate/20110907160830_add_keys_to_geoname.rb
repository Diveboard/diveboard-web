class AddKeysToGeoname < ActiveRecord::Migration
  def self.up
 ###   add_index :geonames_cores, :feature_class
    #add_index :geonames_cores, :name
  ###  add_index :geonames_cores, [:latitude, :longitude]
  ###  add_index :geonames_cores, :feature_code
  ###  add_index :geonames_cores, :country_code
    #add_index :geonames_cores, :cc2
    #add_index :geonames_cores, :admin1_code
    #add_index :geonames_cores, :admin2_code
    #add_index :geonames_cores, :admin3_code
    #add_index :geonames_cores, :admin4_code
  ###  add_index :geonames_cores, :parent_id
    #add_index :geonames_cores, :hierarchy_adm
    
  end

  def self.down
    remove_index :geonames_cores, :feature_class
    #remove_index :geonames_cores, :name
    remove_index :geonames_cores, [:latitude, :longitude]
    remove_index :geonames_cores, :feature_code
    remove_index :geonames_cores, :country_code
    #remove_index :geonames_cores, :cc2
    #remove_index :geonames_cores, :admin1_code
    #remove_index :geonames_cores, :admin2_code
    #remove_index :geonames_cores, :admin3_code
    #remove_index :geonames_cores, :admin4_code
    remove_index :geonames_cores, :parent_id
    #remove_index :geonames_cores, :hierarchy_adm
  end
end
