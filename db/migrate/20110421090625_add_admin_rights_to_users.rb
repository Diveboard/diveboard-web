class AddAdminRightsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin_rights, :integer
  end

  def self.down
    remove_column :users, :admin_rights
  end
end
