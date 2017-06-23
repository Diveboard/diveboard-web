class DropClubs < ActiveRecord::Migration
  def self.up
    drop_table :clubs
  end

  def self.down
    create_table :clubs do |t|
      t.string :name
      t.timestamps
    end
  end
end
