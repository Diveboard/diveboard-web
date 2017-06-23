class AddOrderToGoods < ActiveRecord::Migration
  def self.up
    add_column :goods_to_sell, :order_num, :integer
    execute 'UPDATE goods_to_sell set order_num = id'
    change_column :goods_to_sell, :order_num, :integer, :null => false, :default => -1
    execute "alter table goods_to_sell add column status ENUM('public', 'deleted') NOT NULL DEFAULT 'public'"
  end

  def self.down
    remove_column :goods_to_sell, :order_num
    remove_column :goods_to_sell, :status
  end
end
