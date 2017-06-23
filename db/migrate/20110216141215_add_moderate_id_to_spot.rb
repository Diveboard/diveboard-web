class AddModerateIdToSpot < ActiveRecord::Migration
  def self.up
    add_column :spots, :moderate_id, :integer
  end

  def self.down
    remove_column :spots, :moderate_id
  end
end
