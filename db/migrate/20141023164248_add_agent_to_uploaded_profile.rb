class AddAgentToUploadedProfile < ActiveRecord::Migration
  def change
    add_column :uploaded_profiles, :agent, :string
  end
end
