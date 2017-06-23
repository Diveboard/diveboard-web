class AddIndexToProfiles < ActiveRecord::Migration
  def change
    add_index :uploaded_profiles, [:user_id, :created_at]
  end
end
