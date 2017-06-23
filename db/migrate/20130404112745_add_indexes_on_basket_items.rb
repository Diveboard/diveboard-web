class AddIndexesOnBasketItems < ActiveRecord::Migration
  def self.up
    add_index :basket_items, :basket_id
    add_index :basket_items, :good_to_sell_id
    add_index :basket_histories, :basket_id
  end

  def self.down
    remove_index :basket_items, :basket_id
    remove_index :basket_items, :good_to_sell_id
    remove_index :basket_histories, :basket_id
  end
end
