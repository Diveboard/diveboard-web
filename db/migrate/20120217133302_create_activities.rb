class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.string :tag, :null => false
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
    drop_table :activities
  end
end
