class CreateActivityFollowings < ActiveRecord::Migration
  def self.up
    create_table :activity_followings do |t|
      t.integer :follower_id, :null => false
      t.boolean :exclude, :null => false, :default => false
      t.string :tag
      t.integer :user_id
      t.integer :dive_id
      t.integer :spot_id
      t.integer :location_id
      t.integer :region_id
      t.integer :country_id
      t.integer :shop_id
      t.integer :picture_id
      t.timestamps
    end
  end

  def self.down
    drop_table :activity_followings
  end
end
