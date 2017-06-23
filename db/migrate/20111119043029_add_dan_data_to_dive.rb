class AddDanDataToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :dan_data, :longtext
  end

  def self.down
    remove_column :dives, :dan_data
  end
end
