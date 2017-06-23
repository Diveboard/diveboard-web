class CreateAlbums < ActiveRecord::Migration
  def self.up
    drop_table :albums rescue nil
    remove_column :dives, :album_id rescue nil
    remove_column :trips, :album_id rescue nil
    add_column :dives, :album_id, :integer
    add_column :trips, :album_id, :integer
    create_table :albums do |t|
      t.timestamps
      t.integer :user_id
    end
    add_column :albums, :kind, "ENUM('dive', 'certif', 'trip', 'blog')", :null => false
    execute "UPDATE dives set album_id = id"
    execute "INSERT INTO albums (id, user_id) select id, user_id from dives"
    add_index :dives, :album_id
    add_index :trips, :album_id
    add_index :albums, :user_id
  end

  def self.down
    drop_table :albums
    remove_column :dives, :album_id
    remove_column :trips, :album_id
  end
end
