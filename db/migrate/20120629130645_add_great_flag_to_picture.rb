class AddGreatFlagToPicture < ActiveRecord::Migration
  def self.up
    add_column :pictures, :great_pic, :boolean, :nil => true
  end

  def self.down
    drop_column :pictures, :great_pic
  end
end
