class CreateBasketItems < ActiveRecord::Migration
  def self.up
    create_table :basket_items do |t|
      t.integer :basket_id, :nil => false
      t.integer :good_to_sell_id, :nil => false
      t.text :good_to_sell_archive, :nil => false
      t.integer :quantity, :nil => false
      t.float :price, :precision => 9, :scale => 7, :nil => true
      t.float :tax, :precision => 5, :scale => 3, :nil => true
      t.float :total, :precision => 9, :scale => 7, :nil => true
      t.string :currency, :nil => true
      t.text :details, :nil => true
      t.timestamps
    end
  end

  def self.down
    drop_table :basket_items
  end
end
