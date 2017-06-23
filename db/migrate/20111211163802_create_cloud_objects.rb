class CreateCloudObjects < ActiveRecord::Migration
  def self.up
    create_table :cloud_objects do |t|
      t.string :bucket, :null => false
      t.string :path, :null => false
      t.string :etag, :null => false
      t.integer :size, :null => false
      t.text :meta, :null => true
      t.timestamps
    end
  end

  def self.down
    drop_table :cloud_objects
  end
end
