class AddConstraintOnGearTables < ActiveRecord::Migration
  def self.up
    change_column :user_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Dive skin', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')", :null => false
    change_column :user_gears, :user_id, :integer, :null => false
    change_column :user_gears, :auto_feature, "ENUM('never', 'featured', 'other')", :null => false, :default => 'never'

    change_column :dive_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dive skin', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')", :null => false
    change_column :dive_gears, :dive_id, :integer, :null => false
    change_column :dive_using_user_gears, :user_gear_id, :integer, :null => false
    change_column :dive_using_user_gears, :dive_id, :integer, :null => false
  end

  def self.down
    change_column :user_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Dive skin', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')", :null => true
    change_column :user_gears, :user_id, :integer, :null => true
    change_column :user_gears, :auto_feature, "ENUM('never', 'featured', 'other')", :null => true, :default => 'never'

    change_column :dive_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dive skin', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')", :null => true
    change_column :dive_gears, :dive_id, :integer, :null => true, :default => nil
    change_column :dive_using_user_gears, :user_gear_id, :integer, :null => true, :default => nil
    change_column :dive_using_user_gears, :dive_id, :integer, :null => true, :default => nil
  end
end
