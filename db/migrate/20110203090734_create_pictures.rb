class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.string :url
      t.string :name
      t.integer :service
      t.integer :dive_id
      t.text :tags
      t.boolean :featured

      t.timestamps
    end
  end

  def self.down
    drop_table :pictures
  end
end
