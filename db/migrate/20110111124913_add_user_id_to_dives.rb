class AddUserIdToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :user_id, :integer
  end

  def self.down
    remove_column :dives, :user_id
  end
end
