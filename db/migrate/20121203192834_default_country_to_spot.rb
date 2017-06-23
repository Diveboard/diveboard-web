class DefaultCountryToSpot < ActiveRecord::Migration
  def self.up
    change_column :spots, :country_id, :integer, :default => 1, :null => false
  end

  def self.down
    change_column :spots, :country_id, :integer, :default => 1, :null => true
  end
end
