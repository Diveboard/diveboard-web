class AddModerateFlagToShop < ActiveRecord::Migration
  def self.up
    add_column :shops, :moderate, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :shops, :moderate
  end
end
