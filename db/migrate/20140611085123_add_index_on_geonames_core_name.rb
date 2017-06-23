class AddIndexOnGeonamesCoreName < ActiveRecord::Migration
  def up
    add_index :geonames_cores, [:name, :country_code]
    add_index :geonames_cores, [:asciiname, :country_code]
  end

  def down
    remove_index :geonames_cores, [:name, :country_code]
    remove_index :geonames_cores, [:asciiname, :country_code]
  end
end
