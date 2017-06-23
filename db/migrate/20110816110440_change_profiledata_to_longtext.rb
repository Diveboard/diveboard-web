class ChangeProfiledataToLongtext < ActiveRecord::Migration
  def self.up
    change_column :uploaded_profiles, :data, :longtext
  end

  def self.down
    change_column :uploaded_profiles, :data, :text
  end
end
