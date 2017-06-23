class AddTitleToNewsletter < ActiveRecord::Migration
  def self.up
    add_column :newsletters, :title, :string
  end

  def self.down
    remove_column :newsletters, :title
  end
end
