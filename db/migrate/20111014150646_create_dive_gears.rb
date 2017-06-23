class CreateDiveGears < ActiveRecord::Migration
  def self.up
    create_table :dive_gears do |t|
      t.integer :dive_id
      t.string :manufacturer
      t.string :model
      t.boolean :featured, :null => false, :default => false
      t.timestamps
    end
    add_column :dive_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"

  end

  def self.down
    drop_table :dive_gears
  end
end
