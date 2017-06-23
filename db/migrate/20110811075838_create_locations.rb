class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
      t.string :blob
      t.integer :country_id
      t.integer :wiki_id
      
      
      t.timestamps
    end
    add_index :locations, :country_id
    
    
    
    add_column :spots, :location_id, :integer
    add_index :spots, :location_id
    
  end

  def self.down
    drop_table :locations
    remove_column :spots, :location_id
  end
end
