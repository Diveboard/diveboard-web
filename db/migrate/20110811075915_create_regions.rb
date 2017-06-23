class CreateRegions < ActiveRecord::Migration
  def self.up
    create_table :regions do |t|
      t.string :name
      t.string :blob
      t.integer :wiki_id

      t.timestamps
    end
    add_column :spots, :region_id, :string
    add_index :spots, :region_id
    
  end

  def self.down
    drop_table :regions
    remove_column :spots, :region_id
  end
end
