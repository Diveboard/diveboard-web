class CreateFbComments < ActiveRecord::Migration
  def self.up
    create_table :fb_comments do |t|
      t.string :source_type
      t.integer :source_id
      t.timestamps
    end
    add_column :fb_comments, :raw_data, :longtext
    add_index :fb_comments, :source_type
    add_index :fb_comments, :source_id
  end

  def self.down
    drop_table :fb_comments
  end
end
