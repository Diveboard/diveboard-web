class AddPaypalIdToShop < ActiveRecord::Migration
  def self.up
    add_column :shops, :paypal_id, :string
    add_column :shops, :paypal_token, :string
    add_column :shops, :paypal_secret, :string
  end

  def self.down
    remove_column :shops, :paypal_id
    remove_column :shops, :paypal_token
    remove_column :shops, :paypal_secret
  end
end
