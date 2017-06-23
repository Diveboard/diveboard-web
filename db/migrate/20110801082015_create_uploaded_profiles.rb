class CreateUploadedProfiles < ActiveRecord::Migration
  def self.up
    create_table :uploaded_profiles do |t|
      t.text :source
      t.text :data
      t.text :log
      t.text :source_detail
      t.timestamps
    end
  end

  def self.down
    drop_table :uploaded_profiles
  end
end
