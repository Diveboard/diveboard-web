class UpdatePaymentCancelledSpelling < ActiveRecord::Migration
  def self.up
    change_column :payments, :status, "ENUM('pending', 'confirmed', 'cancelled', 'refunded')", :null => false
    execute "update payments set status='cancelled' where status=''"
    change_column :payments, :status, "ENUM('pending', 'confirmed', 'cancelled', 'refunded')", :null => false, :default => 'pending'
  end

  def self.down
    change_column :payments, :status, "ENUM('pending', 'confirmed', 'canceled', 'refunded')", :null => false
  end
end
