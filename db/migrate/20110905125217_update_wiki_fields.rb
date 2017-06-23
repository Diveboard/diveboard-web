class UpdateWikiFields < ActiveRecord::Migration
  def self.up
    add_column :wikis, :url, :string
    remove_column :wikis, :filename
  end

  def self.down
    remove_column :wikis, :url
    add_column :wikis, :filename, :string
  end
end
