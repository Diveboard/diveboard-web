class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.float :minLat
      t.float :minLng
      t.float :maxLat
      t.float :maxLng
      t.integer :elevation
      t.references :geonames_core
      t.timestamps
    end
  end
end
