class ChangeSpotsColumnType < ActiveRecord::Migration
  def self.up
    change_column :spots, :lat, :decimal, :precision => 10, :scale => 6
    change_column :spots, :long, :decimal, :precision => 10, :scale => 6
  end

  def self.down
    change_column :spots, :lat, :decimal, :precision => 10, :scale => 3
    change_column :spots, :long, :decimal, :precision => 10, :scale => 3
  end
end
