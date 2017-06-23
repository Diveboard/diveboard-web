class CreatePayments < ActiveRecord::Migration
  def self.up
    begin
      drop_table :payments
    rescue
    end
    create_table :payments do |t|
      t.integer :user_id, :null => false
      t.string :status, :null => false
      t.date :confirmation_date
      t.date :cancellation_date
      t.date :refund_date
      t.date :validity_date
      t.float :amount, :null => false
      t.text :ref_paypal
      t.text :comment
      t.integer :storage_duration
      t.integer :storage_limit
      t.timestamps
    end
    begin
      change_column :payments, :status, "ENUM('pending', 'confirmed', 'canceled', 'refunded')", :null => false
      change_column :payments, :storage_limit, :bigint
      change_column :payments, :storage_duration, :bigint
    rescue
      drop_table :payments
      raise
    end
  end

  def self.down
    drop_table :payments
  end
end
