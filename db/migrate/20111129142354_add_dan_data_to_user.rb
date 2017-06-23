class AddDanDataToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :dan_data, :longtext
  end

  def self.down
    remove_column :users, :dan_data
  end
end
