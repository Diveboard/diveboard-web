class AddWikiIdToLocations < ActiveRecord::Migration
  def self.up
    add_column :countries, :wiki_id, :integer
    remove_column :wikis, :blob
    add_column :wikis, :directory, :string
  end

  def self.down
    remove_column :countries, :wiki_id
    add_column :wikis, :blob, :string
    remove_column :wikis, :directory
  end
end
