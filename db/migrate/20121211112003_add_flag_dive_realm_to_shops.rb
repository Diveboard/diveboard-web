class AddFlagDiveRealmToShops < ActiveRecord::Migration
  def self.up
    add_column :shops, :realm_dive, :boolean
  end

  def self.down
    remove_column :shops, :realm_dive
  end
end
