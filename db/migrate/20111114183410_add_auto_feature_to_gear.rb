class AddAutoFeatureToGear < ActiveRecord::Migration
  def self.up
    add_column :user_gears, :auto_feature, "ENUM('never', 'featured', 'other')", :nil => false, :default => 'never'
  end

  def self.down
    remove_column :user_gears, :auto_feature
  end
end
