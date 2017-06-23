class CreateShopDensities < ActiveRecord::Migration
  def change
    create_table :shop_densities do |t|
      t.float :minLat
      t.float :minLng
      t.float :maxLat
      t.float :maxLng
      t.integer :shop_density
      t.integer :dive_density

      t.timestamps
    end
  end
end
