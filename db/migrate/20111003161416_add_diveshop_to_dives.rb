class AddDiveshopToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :diveshop, :text
  end

  def self.down
    remove_column :dives, :diveshop, :text 
  end
end
