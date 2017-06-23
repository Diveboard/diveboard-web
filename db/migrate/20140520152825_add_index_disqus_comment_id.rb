class AddIndexDisqusCommentId < ActiveRecord::Migration
  def up
  	add_index :disqus_comments, :comment_id, :unique => true
  end

  def down
  	remove_index :disqus_comments, :comment_id
  end
end
