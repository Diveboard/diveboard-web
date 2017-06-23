class ChangeRegionIdToStringOnSpots < ActiveRecord::Migration
  def self.up
    change_column :spots, :region_id, :integer
  end

  def self.down
    change_column :spots, :region_id, :string
  end
end
