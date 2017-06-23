class AddDepositToStuffToSell < ActiveRecord::Migration
  def self.up
    add_column :goods_to_sell, :deposit, :float, :null => true
    add_column :basket_items, :deposit_option, :bool, :null => false, :default => false
    add_column :basket_items, :deposit, :float, :null => true
  end

  def self.down
    remove_column :goods_to_sell, :deposit
    remove_column :basket_items, :deposit
    remove_column :basket_items, :deposit_option
  end
end
