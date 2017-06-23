class AddPrivacyToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :privacy, :integer
    # we need to update our seed data
  end

  def self.down
    remove_column :dives, :privacy
  end
end
