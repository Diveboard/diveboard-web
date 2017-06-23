class AddIndexOnProfileData < ActiveRecord::Migration
  def self.up
    add_index :profile_data, :dive_id
  end

  def self.down
    remove_index :profile_data, :dive_id
  end
end
