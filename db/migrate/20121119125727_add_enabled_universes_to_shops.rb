class AddEnabledUniversesToShops < ActiveRecord::Migration
  def self.up
    add_column :shops, :realms, :string
  end

  def self.down
    remove_column :shops, :realms
  end
end
