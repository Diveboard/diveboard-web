class AddGeonamesCoreIdToRegions < ActiveRecord::Migration
  def change
    add_column :regions, :geonames_core_id, :integer
  end
end
