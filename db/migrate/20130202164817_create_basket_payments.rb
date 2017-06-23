class CreateBasketPayments < ActiveRecord::Migration
  def self.up
    begin
      drop_table :basket_payments
    rescue
    end
    create_table :basket_payments do |t|
      t.integer :user_id, :null => false
      t.string :status, :null => false
      t.date :confirmation_date
      t.date :cancellation_date
      t.date :refund_date
      t.date :validity_date
      t.float :amount, :null => false
      t.string :currency, :null => false
      t.text :ref_paypal
      t.text :comment
      t.timestamps
    end
    begin
      change_column :basket_payments, :status, "ENUM('pending', 'confirmed', 'cancelled', 'refunded')", :null => false, :default => 'pending'
    rescue
      drop_table :basket_payments
      raise
    end
  end

  def self.down
    drop_table :basket_payments
  end
end
