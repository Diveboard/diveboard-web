class AddBuddiesToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :buddies, :text
  end

  def self.down
    remove_column :dives, :buddies, :text 
  end
end
