class AddShopProxyToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :shop_proxy_id, :integer, :null => true
  end

  def self.down
    remove_column :users, :shop_proxy_id
  end
end
