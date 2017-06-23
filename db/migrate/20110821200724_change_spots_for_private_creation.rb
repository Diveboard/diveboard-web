class ChangeSpotsForPrivateCreation < ActiveRecord::Migration
  def self.up
    add_column :spots, :private_user_id, :integer
    add_column :spots, :flag_moderate_private_to_public, :boolean
    add_column :locations, :private_user_id, :integer
    add_column :locations, :flag_moderate_private_to_public, :boolean
    add_column :regions, :private_user_id, :integer
    add_column :regions, :flag_moderate_private_to_public, :boolean
  end

  def self.down
    remove_column :spots, :private_user_id
    remove_column :spots, :flag_moderate_private_to_public
    remove_column :locations, :private_user_id
    remove_column :locations, :flag_moderate_private_to_public
    remove_column :regions, :private_user_id
    remove_column :regions, :flag_moderate_private_to_public
  end
end
