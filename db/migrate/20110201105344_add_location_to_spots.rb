class AddLocationToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :lat, :decimal, :precision => 10, :scale => 3
    add_column :spots, :long, :decimal, :precision => 10, :scale => 3
    add_column :spots, :zoom, :integer
  end

  def self.down
    remove_column :spots, :zoom
    remove_column :spots, :long
    remove_column :spots, :lat
  end
end
