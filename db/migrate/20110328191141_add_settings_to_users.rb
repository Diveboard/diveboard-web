class AddSettingsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :settings, :text
    User.all.each do |user|
      user.settings="{}"
      user.save
    end
  end

  def self.down
    remove_column :users, :settings
  end
end
