class CreateUserExtraActivities < ActiveRecord::Migration
  def change
    create_table :user_extra_activities do |t|
      t.integer :user_id
      t.integer :geoname_id
      t.float :lat, nil: false
      t.float :lng, nil: false
      t.integer :year
      t.timestamps
    end
  end
end
