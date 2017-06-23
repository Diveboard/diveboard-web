class AddIndexesShops < ActiveRecord::Migration
  def self.up
    add_index :dives, :shop_id
    add_index :users, :shop_proxy_id
  end

  def self.down
    remove_index :dives, :shop_id
    remove_index :users, :shop_proxy_id
  end
end
