class AddPrivateModerationToShop < ActiveRecord::Migration
  def self.up
    add_column :shops, :private_user_id, :integer, :nil => true, :default => nil
    add_column :shops, :flag_moderate_private_to_public, :boolean, :nil => true, :default => nil
  end

  def self.down
    remove_column :shops, :private_user_id
    remove_column :shops, :flag_moderate_private_to_public
  end
end
