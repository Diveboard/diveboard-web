class CreateDisqusComments < ActiveRecord::Migration
  def change
    create_table :disqus_comments do |t|
      t.string :comment_id
      t.string :thread_id
      t.string :thread_link
      t.string :forum_id
      t.string :parent_comment_id
      t.text   :body
      t.string :author_name
      t.string :author_email
      t.string :author_url
      t.datetime :date
      t.string :source_type
      t.integer :source_id
      t.integer :diveboard_id
      t.string :connections

      t.timestamps
    end
    add_index :disqus_comments, [:source_type, :source_id] 
  end
end
