class AddSkinToGearCategories < ActiveRecord::Migration
  def self.up
    change_column :user_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Dive skin', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"
    change_column :dive_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dive skin', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"
  end

  def self.down
    change_column :user_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"
    change_column :dive_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"
  end
end
