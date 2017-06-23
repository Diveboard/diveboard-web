class CreateDives < ActiveRecord::Migration
  def self.up
    create_table :dives do |t|
      t.integer :diver_id
      t.string :spot_name
      t.string :location
      t.datetime :time_in
      t.integer :duration
      t.text :profile_data

      t.timestamps
    end
  end

  def self.down
    drop_table :dives
  end
end
