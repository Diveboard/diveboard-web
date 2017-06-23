class MovePaypalLogicToBaskets < ActiveRecord::Migration
  def self.up
    drop_table :basket_payments
    remove_column :baskets, :basket_payment_id
    add_column :baskets, :paypal_order_id, :string, :limit => 25
    add_column :baskets, :paypal_order_date, :datetime
    add_column :baskets, :paypal_auth_id, :string, :limit => 25
    add_column :baskets, :paypal_auth_date, :datetime
    add_column :baskets, :paypal_capture_id, :string, :limit => 25
    add_column :baskets, :paypal_capture_date, :datetime
    add_column :baskets, :paypal_refund_id, :string, :limit => 25
    add_column :baskets, :paypal_refund_date, :datetime
    add_column :baskets, :paypal_issue, :string, :limit => 2048
    add_column :baskets, :paypal_attention, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :baskets, :paypal_order_id
    remove_column :baskets, :paypal_order_date
    remove_column :baskets, :paypal_auth_id
    remove_column :baskets, :paypal_auth_date
    remove_column :baskets, :paypal_capture_id
    remove_column :baskets, :paypal_capture_date
    remove_column :baskets, :paypal_refund_id
    remove_column :baskets, :paypal_refund_date
    remove_column :baskets, :paypal_issue
    remove_column :baskets, :paypal_attention
  end
end
