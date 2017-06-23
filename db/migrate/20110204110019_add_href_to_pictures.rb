class AddHrefToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :href, :string
  end

  def self.down
    remove_column :pictures, :href
  end
end
