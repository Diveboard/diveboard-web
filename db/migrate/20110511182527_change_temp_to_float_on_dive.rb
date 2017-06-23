class ChangeTempToFloatOnDive < ActiveRecord::Migration
  def self.up
    change_column :dives, :temp_bottom, :float
    change_column :dives, :temp_surface, :float
  end

  def self.down
    change_column :dives, :temp_bottom, :integer
    change_column :dives, :temp_surface, :integer
  end
end
