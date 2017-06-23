class CreateGoodsToSell < ActiveRecord::Migration
  def self.up
    create_table :goods_to_sell do |t|
      t.integer :shop_id, :null => false
      t.string :realm, :null => false
      t.string :cat1
      t.string :cat2
      t.string :cat3
      t.text :title, :null => false
      t.text :description
      t.integer :picture_id
      t.string :stock_type
      t.integer :stock_id
      t.string :price_type
      t.float :price
      t.float :tax
      t.float :total
      t.string :currency, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :goods_to_sell
  end
end
