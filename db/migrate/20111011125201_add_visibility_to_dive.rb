class AddVisibilityToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :visibility, "ENUM('bad', 'average', 'good', 'excellent')"
    
  end

  def self.down
    remove_column :dives, :visibility
  end
end
