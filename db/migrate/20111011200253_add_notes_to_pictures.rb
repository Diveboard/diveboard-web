class AddNotesToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :notes, :text
  end

  def self.down
    remove_column :pictures, :notes
  end
end
