class AddingSpotAndLocationDefaults < ActiveRecord::Migration
  def self.up
    execute "update dives set spot_id = 1 where spot_id is null"
    change_column :dives, :spot_id, :integer, :null => false, :default => 1
    execute "update spots set location_id = 1 where location_id is null"
    change_column :spots, :location_id, :integer, :null => false, :default => 1
  end

  def self.down
    change_column :dives, :spot_id, :integer, :null => true, :default => nil
    change_column :spots, :location_id, :integer, :null => true, :default => 1
  end
end
