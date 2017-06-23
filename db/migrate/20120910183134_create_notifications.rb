class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.integer :user_id, :null => false
      t.string :kind, :null => false
      t.timestamps
      t.datetime :dismissed_at
      t.integer :dive_id
      t.integer :advertisement_id
    end
    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, :dive_id
    add_index :notifications, :advertisement_id
  end

  def self.down
    drop_table :notifications
  end
end
