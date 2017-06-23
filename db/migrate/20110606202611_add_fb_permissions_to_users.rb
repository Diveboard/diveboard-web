class AddFbPermissionsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_permissions, :text
  end

  def self.down
    remove_column :users, :fb_permissions
  end
end
