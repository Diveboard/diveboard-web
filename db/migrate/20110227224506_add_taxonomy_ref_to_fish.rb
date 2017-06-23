class AddTaxonomyRefToFish < ActiveRecord::Migration
  def self.up
    add_column :fishes, :taxonomy_id, :integer
    add_column :fishes, :preferred, :boolean
  end

  def self.down
    remove_column :fishes, :taxonomy_id
    remove_column :fishes, :preferred
  end
end
