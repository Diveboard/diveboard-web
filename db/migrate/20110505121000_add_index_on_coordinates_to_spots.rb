class AddIndexOnCoordinatesToSpots < ActiveRecord::Migration
  def self.up
    add_index :spots, [:lat, :long]
  end

  def self.down
    remove_index :spots, [:lat, :long]
  end
end
