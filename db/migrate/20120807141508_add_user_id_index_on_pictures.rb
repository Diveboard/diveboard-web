class AddUserIdIndexOnPictures < ActiveRecord::Migration
  def self.up
    add_index :pictures, :user_id
  end

  def self.down
    remove_index :pictures, :user_id
  end
end
