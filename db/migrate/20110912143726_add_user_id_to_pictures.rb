class AddUserIdToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :user_id, :integer
    execute 'update pictures set user_id = (select user_id from dives where dives.id = pictures.id)'
  end

  def self.down
    remove_column :pictures, :user_id
  end
end
