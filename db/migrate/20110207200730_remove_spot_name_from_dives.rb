class RemoveSpotNameFromDives < ActiveRecord::Migration
  def self.up
  	remove_column :dives, :spot_name
  end

  def self.down
  	add_column :dives, :spot_name, :string
  end
end
