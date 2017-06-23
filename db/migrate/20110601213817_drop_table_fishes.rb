class DropTableFishes < ActiveRecord::Migration
  def self.up
    drop_table :fishes
  end

  def self.down
    create_table :fishes do |t|
      t.string   :name
      t.timestamps
      t.integer :taxonomy_id
      t.boolean :preferred
      t.string :scientific_name
    end
  end
end 
