class CreateEmailMarketings < ActiveRecord::Migration
  def self.up
    create_table :emails_marketing do |t|
      #target_id, target_type , rcpt_id, rcpt_type, email, notif_type
      t.integer :target_id
      t.string :target_type
      t.integer :recipient_id
      t.string :recipient_type
      t.string :email
      t.string :content
      t.timestamps
    end
    add_index :emails_marketing, :email
    add_index :emails_marketing, :content
  end

  def self.down
    drop_table :emails_marketing
  end
end
