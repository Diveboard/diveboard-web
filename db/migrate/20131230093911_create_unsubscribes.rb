class CreateUnsubscribes < ActiveRecord::Migration
  def self.up
    create_table :unsubscribes do |t|
      t.string :email
      t.string :scope
      t.timestamps
    end
    add_index :unsubscribes, :email
    add_index :unsubscribes, :scope
  end

  def self.down
    drop_table :unsubscribes
  end
end
