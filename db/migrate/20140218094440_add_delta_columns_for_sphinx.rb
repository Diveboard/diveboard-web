class AddDeltaColumnsForSphinx < ActiveRecord::Migration
  def up
    #skipping countries, eolcnames, eolsnames, geonames_alternate_names
    add_column :users, :delta, :boolean, :default => true, :null => false
    add_column :blog_posts, :delta, :boolean, :default => true, :null => false
    add_column :dives, :delta, :boolean, :default => true, :null => false
    add_column :locations, :delta, :boolean, :default => true, :null => false
    add_column :regions, :delta, :boolean, :default => true, :null => false
    add_column :shops, :delta, :boolean, :default => true, :null => false
    add_column :spots, :delta, :boolean, :default => true, :null => false


    add_index :users, :delta
    add_index :blog_posts, :delta
    add_index :dives, :delta
    add_index :locations, :delta
    add_index :regions, :delta
    add_index :shops, :delta
    add_index :spots, :delta


  end

  def down
    remove_column :users, :delta
    remove_column :blog_posts, :delta
    remove_column :dives, :delta
    remove_column :locations, :delta
    remove_column :regions, :delta
    remove_column :shops, :delta
    remove_column :spots, :delta
  end
end
