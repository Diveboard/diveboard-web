class CreateAdvertisements < ActiveRecord::Migration
  def self.up
    create_table :advertisements do |t|
      t.integer :user_id, :null => false
      t.timestamps
      t.datetime :ended_at
      t.boolean :deleted, :null => false, :default => false
      t.string :title, :null => false
      t.string :text, :null => false
      t.float :lat
      t.float :lng
      t.integer :picture_id, :null => false
      t.string :external_url, :null => true
      t.boolean :local_divers, :null => false, :default => false
      t.boolean :frequent_divers, :null => false, :default => false
      t.boolean :exploring_divers, :null => false, :default => false
    end
    add_index :advertisements, :user_id
    add_index :advertisements, [:lat, :lng]
    add_index :users, [:lat, :lng]
  end

  def self.down
    drop_table :advertisements
    remove_index :users, [:lat, :lng]
  end
end
