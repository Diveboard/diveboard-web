class AddRegionToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :region, :string
  end

  def self.down
    remove_column :dives, :region
  end
end
