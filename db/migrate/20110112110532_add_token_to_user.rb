class AddTokenToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :token, :text
  end

  def self.down
    remove_column :users, :token
  end
end
