class AddScoreToShop < ActiveRecord::Migration
  def self.up
    add_column :shops, :score, :integer, :null => false, :default => -1
  end

  def self.down
    remove_column :shops, :score
  end
end
