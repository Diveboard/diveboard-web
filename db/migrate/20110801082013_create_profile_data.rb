class CreateProfileData < ActiveRecord::Migration
  def self.up
    create_table :profile_data do |t|
      t.integer :dive_id, :null => false
      t.integer :seconds, :null => false
      t.float   :depth
      t.float   :current_water_temperature
      t.float   :main_cylinder_pressure
      t.float   :heart_beats
      t.boolean    :deco_violation, :null => false, :default => false
      t.boolean    :deco_start, :null => false, :default => false
      t.boolean    :ascent_violation, :null => false, :default => false
      t.boolean    :bookmark, :null => false, :default => false
      t.boolean    :surface_event, :null => false, :default => false
    end
  end

  def self.down
    drop_table :profile_data
  end
end
