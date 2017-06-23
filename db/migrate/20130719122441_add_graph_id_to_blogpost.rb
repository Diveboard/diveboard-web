class AddGraphIdToBlogpost < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :fb_graph_id, :string
  end

  def self.down
    remove_column :blog_posts, :fb_graph_id
  end
end
