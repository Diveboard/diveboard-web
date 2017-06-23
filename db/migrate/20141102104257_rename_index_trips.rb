class RenameIndexTrips < ActiveRecord::Migration
  def up
    remove_index :trips, name: 'user_id'
    add_index :trips, :user_id
  end

  def down
    remove_index :trips, :user_id
    add_index :trips, :user_id, name: 'user_id'
  end

end
