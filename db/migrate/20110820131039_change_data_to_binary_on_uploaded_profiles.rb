class ChangeDataToBinaryOnUploadedProfiles < ActiveRecord::Migration
  def self.up
    change_column :uploaded_profiles, :data, :binary, :limit => 50.megabyte
  end

  def self.down
  end
end
