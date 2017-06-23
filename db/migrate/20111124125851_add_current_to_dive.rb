class AddCurrentToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :current, "ENUM('none', 'light', 'medium', 'strong', 'extreme')"
  end

  def self.down
    remove_column :dives, :current
  end
end
