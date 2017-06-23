class AddConstraintsOnBlogpostFields < ActiveRecord::Migration
  def self.up
    #adding default values and constratins blog_category_id not null & published false by default
    change_column :blog_posts, :blog_category_id, :integer, :default => 1
    change_column :blog_posts, :published, :boolean, :default => false
    BlogPost.where(:published => nil) do |b|
      b.published = false
      b.save
    end
  end

  def self.down
    change_column :blog_posts, :blog_category_id, :integer
    change_column :blog_posts, :published, :boolean
  end
end
