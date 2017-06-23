class RenameIndexZzFbUsers < ActiveRecord::Migration
  def up
    remove_index :ZZ_users_fb_data, name: 'user_id'
    add_index :ZZ_users_fb_data, :user_id
  end

  def down
    remove_index :ZZ_users_fb_data, :user_id
    add_index :ZZ_users_fb_data, :user_id, name: 'user_id'
  end

end
