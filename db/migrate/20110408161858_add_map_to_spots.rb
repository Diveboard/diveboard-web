class AddMapToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :map, :string
  end

  def self.down
    remove_column :spots, :map
  end
end
