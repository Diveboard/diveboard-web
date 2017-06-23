class AddWeightsToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :weights, :float
  end

  def self.down
    remove_column :dives, :weights
  end
end
