class AddPictureToNotification < ActiveRecord::Migration
  def self.up
    add_column :notifications, :picture_id, :integer
  end

  def self.down
    remove_column :notifications, :picture_id
  end
end
