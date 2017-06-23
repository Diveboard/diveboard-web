class AddTempSurfaceAndTempBottomToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :temp_surface, :integer
    add_column :dives, :temp_bottom, :integer
  end

  def self.down
    remove_column :dives, :temp_bottom
    remove_column :dives, :temp_surface
  end
end
