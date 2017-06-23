class AddAltitudeWaterToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :water, "ENUM('salt', 'fresh')"
    add_column :dives, :altitude, :float
  end

  def self.down
    remove_column :dives, :water
    remove_column :dives, :altitude
  end
end
