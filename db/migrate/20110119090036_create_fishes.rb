class CreateFishes < ActiveRecord::Migration
  def self.up
    create_table :fishes do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :fishes
  end
end
