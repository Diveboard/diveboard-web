class AddSizeToPicture < ActiveRecord::Migration
  def self.up
    add_column :pictures, :size, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :pictures, :size
  end
end
