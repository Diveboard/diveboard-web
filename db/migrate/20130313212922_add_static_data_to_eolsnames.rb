class AddStaticDataToEolsnames < ActiveRecord::Migration
  def self.up
     add_column :eolsnames, :eol_description, :longtext
     add_column :eolsnames, :thumbnail_href, :string
  end

  def self.down
    remove_column :eolsnames, :eol_description
    remove_column :eolsnames, :thumbnail_href
  end
end
