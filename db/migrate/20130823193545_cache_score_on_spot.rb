class CacheScoreOnSpot < ActiveRecord::Migration
  def self.up
    add_column :spots, :score, :integer
  end

  def self.down
    remove_column :spots, :score
  end
end
