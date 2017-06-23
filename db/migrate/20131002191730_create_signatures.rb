class CreateSignatures < ActiveRecord::Migration
  def self.up
    create_table :signatures do |t|
      t.integer :dive_id
      t.string :signby_type
      t.integer :signby_id
      t.text :signed_data
      t.datetime :request_date
      t.datetime :signed_date
      t.boolean :rejected, :default =>false
      t.datetime :notified_at
      t.timestamps
    end
  end

  def self.down
    drop_table :signatures
  end
end
