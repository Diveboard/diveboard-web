class AddIndexesToActivitiesTables < ActiveRecord::Migration
  def self.up
    begin
      add_index :activities, :user_id
      add_index :activities, :dive_id 
      add_index :activities, :spot_id
      add_index :activities, :location_id
      add_index :activities, :region_id
      add_index :activities, :country_id
      add_index :activities, :picture_id
      add_index :activities, :shop_id
      add_index :activities, [:tag, :user_id, :dive_id, :spot_id, :location_id, :region_id, :country_id, :shop_id, :picture_id], :name => 'index_activities_all'
      add_index :activity_followings, [:follower_id, :tag, :user_id, :dive_id, :spot_id, :location_id, :region_id, :country_id, :shop_id, :picture_id], :unique => true, :name => 'index_activities_following_all'
    rescue 
      puts $!
      self.down
      throw $!
    end
  end

  def self.down
      remove_index :activities, :user_id rescue puts $!
      remove_index :activities, :dive_id  rescue puts $!
      remove_index :activities, :spot_id rescue puts $!
      remove_index :activities, :picture_id rescue puts $!
      remove_index :activities, :shop_id rescue puts $!
      remove_index :activities, :name => 'index_activities_all' rescue puts $!
      remove_index :activity_followings, :name => 'index_activities_following_all' rescue puts $!
  end
end
