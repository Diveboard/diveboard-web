class CreateFbLikes < ActiveRecord::Migration
  def self.up
    create_table :fb_likes do |t|
      t.string :source_type, :null => false
      t.integer :source_id, :null => false
      t.string :url, :null => false
      t.integer :click_count
      t.integer :comment_count
      t.integer :comments_fbid
      t.integer :commentsbox_count
      t.integer :like_count
      t.integer :share_count
      t.integer :total_count
      t.timestamps
    end

    add_index :fb_likes, :url, :unique => true
  end

  def self.down
    drop_table :fb_likes
  end
end
