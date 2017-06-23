class AddScientificNameToFish < ActiveRecord::Migration
  def self.up
    add_column :fishes, :scientific_name, :string
  end

  def self.down
    remove_column :fishes, :scientific_name
  end
end
