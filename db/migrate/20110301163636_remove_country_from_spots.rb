class RemoveCountryFromSpots < ActiveRecord::Migration
  def self.up
    remove_column :spots, :country
  end

  def self.down
    add_column :spots, :country, :string
  end
end
