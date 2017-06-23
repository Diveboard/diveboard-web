class AddUserIdToUploadedProfile < ActiveRecord::Migration
  def change
    add_column :uploaded_profiles, :user_id, :integer
  end
end
