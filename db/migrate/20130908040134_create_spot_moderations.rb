class CreateSpotModerations < ActiveRecord::Migration
  def self.up
    create_table :spot_moderations do |t|
      t.integer :a_id
      t.integer :b_id
      t.timestamps
    end

    add_index :spot_moderations, [:a_id, :b_id]
    add_index :spot_moderations, [:b_id, :a_id]

  end

  def self.down
    drop_table :spot_moderations
  end
end
