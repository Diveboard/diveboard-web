class AddDimensionsToPicture < ActiveRecord::Migration
  def self.up
    add_column :pictures, :width, :integer
    add_column :pictures, :height, :integer
  end

  def self.down
    remove_column :pictures, :width 
    remove_column :pictures, :height
  end
end
