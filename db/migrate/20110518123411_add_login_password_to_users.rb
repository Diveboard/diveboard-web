class AddLoginPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :login, :string
    add_column :users, :password, :string
  end

  def self.down
    remove_column :users, :password
    remove_column :users, :login
  end
end
