class AddParamToNotifications < ActiveRecord::Migration
  def self.up
    add_column :notifications, :param, :text
  end

  def self.down
    remove_column :notifications, :param
  end
end
