class AddCachedBestPicToCountry < ActiveRecord::Migration
  def self.up
    add_column :countries, :best_pic_ids, :string, :null => true
    add_column :locations, :best_pic_ids, :string, :null => true
    add_column :regions, :best_pic_ids, :string, :null => true
    add_column :spots, :best_pic_ids, :string, :null => true
  end

  def self.down
    remove_column :countries, :best_pic_ids
    remove_column :locations, :best_pic_ids
    remove_column :regions, :best_pic_ids
    remove_column :spots, :best_pic_ids
  end
end
