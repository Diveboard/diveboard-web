class AddIndexToBlobs < ActiveRecord::Migration
  def self.up
    add_index :countries, :blob
    add_index :locations, :blob
    add_index :regions, :blob
  end

  def self.down
    remove_index :countries, :blob
    remove_index :locations, :blob
    remove_index :regions, :blob
  end
end
