class AddDetailsToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :location, :string
    add_column :spots, :region, :string
    add_column :spots, :country, :string
    add_column :spots, :type, :integer
    add_column :dives, :spot_id, :integer
    remove_column :dives, :location
    remove_column :dives, :region

  end

  def self.down
    remove_column :spots, :type
    remove_column :spots, :country
    remove_column :spots, :region
    remove_column :spots, :location
    remove_column :dives, :spot_id
    add_column :dives, :location, :string
    add_column :dives, :region, :string
  end
end
