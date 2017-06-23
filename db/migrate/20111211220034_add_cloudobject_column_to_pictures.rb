class AddCloudobjectColumnToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :small_id, :integer
    add_column :pictures, :medium_id, :integer
    add_column :pictures, :original_id, :integer
  end

  def self.down
    remove_column :pictures, :small_id
    remove_column :pictures, :medium_id
    remove_column :pictures, :original_id
  end
end
