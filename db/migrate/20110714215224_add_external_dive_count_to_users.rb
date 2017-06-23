class AddExternalDiveCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :total_ext_dives, :integer, :default => 0
  end

  def self.down
    remove_column :users, :total_ext_dives
  end
end
