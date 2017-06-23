class AddLinkWithUploadedProfileToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :uploaded_profile_id, :integer
    add_column :dives, :uploaded_profile_index, :integer
  end

  def self.down
    remove_column :dives, :uploaded_profile_id
    remove_column :dives, :uploaded_profile_index
  end
end
