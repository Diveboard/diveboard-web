class AddNumberToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :number, :integer
  end

  def self.down
    remove_column :dives, :number 
  end
end
