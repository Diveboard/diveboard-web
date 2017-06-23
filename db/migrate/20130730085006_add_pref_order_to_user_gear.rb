class AddPrefOrderToUserGear < ActiveRecord::Migration
  def self.up
    add_column :user_gears, :pref_order, :integer
  end

  def self.down
    remove_column :user_gears, :pref_order
  end
end
