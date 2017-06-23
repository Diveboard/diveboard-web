class CreateBlogPosts < ActiveRecord::Migration
  def self.up
    create_table :blog_posts do |t|
      #t.string :title
      t.integer :blog_category_id
      t.integer :user_id
      t.string :blob
      t.boolean :published
      t.datetime :published_at
      t.timestamps
      t.boolean :wordpress_article, :default => false
      t.boolean :flag_moderate_private_to_public, :default => false
      t.boolean :comments_question, :default => false
    end
    create_table :blog_categories do |t|
      t.string :name
      t.string :blob
      t.timestamps
    end

    create_table :content_flags do |t|
      t.string :type
      t.text :data
      t.integer :user_id
      t.integer :object_id
    end

    add_column :content_flags, :object_type, "ENUM('Spot', 'Country', 'Location', 'Region', 'BlogPost', 'Wiki')"

    add_column :wikis, :album_id, :integer
    add_column :wikis, :title, :string
    add_index :blog_posts, :blob
    add_index :blog_categories, :blob
    add_index :blog_categories, :name

    change_column :wikis, :object_type, "ENUM('Spot', 'Country', 'Location', 'Region', 'BlogPost')"
    rename_column :wikis, :object_type, :source_type
    rename_column :wikis, :object_id, :source_id
    ##migrating the blog posts
    config = DiveBoard::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["blog_database"]
    username = config.database_configuration[RAILS_ENV]["blog_username"]
    password = config.database_configuration[RAILS_ENV]["blog_password"]
    socket = config.database_configuration[RAILS_ENV]["socket"]
    client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
    result = client.query("SELECT * FROM `wp_posts` WHERE (`post_status` LIKE \"publish\" AND `post_type` LIKE \"post\");")

    result.each do |r|
      b = BlogPost.new
      b.user = User.find(30)
      #b.title = r["post_title"]
      b.published = true
      b.published_at = r["post_date"]
      b.blob = r["post_name"]
      g= client.query("SELECT * FROM `wp_terms` LEFT JOIN `wp_term_relationships` on wp_terms.term_id = wp_term_relationships.term_taxonomy_id  WHERE wp_term_relationships.object_id = #{r["ID"]} LIMIT 1;").first
      if !g.nil?
        c = BlogCategory.find_or_create_by_name g["name"] {|bc|
            bc.blob = g["slug"]
          }
        b.blog_category = c
      end
      b.wordpress_article = true
      b.flag_moderate_private_to_public = nil
      b.save
      w=b.update_wiki({:text => r["post_content"].gsub("\n", "<br/>").gsub("\r", "").gsub(/\[([^\]]+)\]/, '<\1 />'), :title => r["post_title"]})
      w.verified_user_id = b.user.id ## alex has checked them all :)
      w.save
      b.update_blob
      b.save
      puts "no category for #{b.id}" if b.blog_category.nil?
    end
  end

  def self.down
    drop_table :blog_posts
    drop_table :blog_categories
    remove_column :wikis, :album_id
    rename_column :wikis, :source_type, :object_type
    rename_column :wikis, :source_id, :object_id
    Wiki.where("object_type = ?", "Blog Post").each do |o| o.destroy end
    change_column :wikis, :object_type, "ENUM('Spot', 'Country', 'Location', 'Region')"

  end
end
