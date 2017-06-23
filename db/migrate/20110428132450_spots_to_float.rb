class SpotsToFloat < ActiveRecord::Migration
  def self.up
    change_column :spots, :lat, :float
    change_column :spots, :long, :float
    add_column :spots, :latitude, :decimal, :precision => 10, :scale => 6
    add_column :spots, :longitude, :decimal, :precision => 10, :scale => 6
  end

  def self.down
    change_column :spots, :lat, :decimal, :precision => 10, :scale => 6
    change_column :spots, :long, :decimal, :precision => 10, :scale => 6
    remove_column :spots, :longitude
    remove_column :spots, :latitude
  end
end
