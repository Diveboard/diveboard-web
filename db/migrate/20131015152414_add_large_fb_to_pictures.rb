class AddLargeFbToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :large_fb_id, :integer, :after => :large_id
  end

  def self.down
    remove_column :pictures, :large_fb_id
  end
end
