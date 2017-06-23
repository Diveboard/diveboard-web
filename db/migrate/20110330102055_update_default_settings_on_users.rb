class UpdateDefaultSettingsOnUsers < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      user.settings="{}"
      user.save
    end
  end

  def self.down
  end
end
