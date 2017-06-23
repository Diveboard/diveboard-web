class SetDefaultToSpotFromBulk < ActiveRecord::Migration
  def self.up
    change_column :spots, :from_bulk, :boolean, :default => false
  end

  def self.down
    change_column :spots, :from_bulk, :boolean, :default => nil
  end
end
