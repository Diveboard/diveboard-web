class CreateInternalMessages < ActiveRecord::Migration
  def self.up
    create_table :internal_messages do |t|
      t.integer :from_id, :nil => false
      t.integer :from_group_id, :nil => true
      t.integer :to_id, :nil => false
      t.string :topic, :nil => false
      t.text :message, :nil => false
      t.string :in_reply_to_type, :nil => true
      t.integer :in_reply_to_id, :nil => true
      t.integer :basket_id, :nil => true
      t.timestamps
    end
  end

  def self.down
    drop_table :internal_messages
  end
end
