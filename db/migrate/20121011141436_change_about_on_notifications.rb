class ChangeAboutOnNotifications < ActiveRecord::Migration
  def self.up
    add_column :notifications, :about_type, :string, :null => false
    add_column :notifications, :about_id, :integer, :null => false    
    remove_column :notifications, :dive_id
    remove_column :notifications, :advertisement_id
    remove_column :notifications, :picture_id
  end

  def self.down
    remove_column :notifications, :about_type
    remove_column :notifications, :about_id
    add_column :notifications, :dive_id, :integer, :null => true
    add_column :notifications, :advertisement_id, :integer, :null => true
    add_column :notifications, :picture_id, :integer, :null => true
  end
end
