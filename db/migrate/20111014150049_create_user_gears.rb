class CreateUserGears < ActiveRecord::Migration
  def self.up
    create_table :user_gears do |t|
      t.integer :user_id
      t.string :manufacturer
      t.string :model
      t.date :acquisition
      t.date :last_revision
      t.string :reference
      t.timestamps
    end
    add_column :user_gears, :category, "ENUM('BCD', 'Boots', 'Computer', 'Compass', 'Camera', 'Cylinder', 'Dry suit', 'Fins', 'Gloves', 'Hood', 'Knife', 'Light', 'Lift bag', 'Mask', 'Other', 'Rebreather', 'Regulator', 'Scooter', 'Wet suit')"
  end

  def self.down
    drop_table :user_gears
  end
end
