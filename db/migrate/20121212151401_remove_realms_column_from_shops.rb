class RemoveRealmsColumnFromShops < ActiveRecord::Migration
  def self.up
    remove_column :shops, :realms
    add_column :shops, :realm_home, :boolean
    add_column :shops, :realm_gear, :boolean
    add_column :shops, :realm_travel, :boolean
  end

  def self.down
    add_column :shops, :realms, :string
    remove_column :shops, :realm_home
    remove_column :shops, :realm_gear
    remove_column :shops, :realm_travel
  end
end
