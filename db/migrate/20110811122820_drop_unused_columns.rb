class DropUnusedColumns < ActiveRecord::Migration
  def self.up
    remove_column :spots, :location_name
    remove_column :spots, :region_name
    remove_column :spots, :country_code
  end

  def self.down
  end
end
