class CreateBaskets < ActiveRecord::Migration
  def self.up
    create_table :baskets do |t|
      t.integer :user_id, :nil => false
      t.integer :shop_id, :nil => false
      t.text :comment, :nil => true
      t.text :note_from_shop, :nil => true
      t.string :in_reply_to_type, :nil => true
      t.integer :in_reply_to_id, :nil => true
      t.string :status, :nil => false, :default => 'open'
      t.text :delivery_address, :nil => true
      t.float :paypal_fees, :nil => true, :precision => 9, :scale => 7
      t.string :paypal_fees_currency, :nil => true
      t.float :diveboard_fees, :nil => true, :precision => 9, :scale => 7
      t.string :diveboard_fees_currency, :nil => true
      t.integer :basket_payment_id, :nil => true
      t.timestamps
    end
  end

  def self.down
    drop_table :baskets
  end
end
