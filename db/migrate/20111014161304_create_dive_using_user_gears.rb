class CreateDiveUsingUserGears < ActiveRecord::Migration
  def self.up
    create_table :dive_using_user_gears do |t|
      t.integer :user_gear_id
      t.integer :dive_id
      t.boolean :featured, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :dive_using_user_gears
  end
end
