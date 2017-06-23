class AddTripToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :trip_name, :string
  end

  def self.down
    remove_column :dives, :trip_name
  end
end
