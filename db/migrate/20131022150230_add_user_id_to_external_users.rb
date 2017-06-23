class AddUserIdToExternalUsers < ActiveRecord::Migration
  def self.up
    add_column :external_users, :user_id, :integer
  end

  def self.down
    remove_column :external_users, :user_id
  end
end
