class AddEolFullHierarchyData < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :worms_hierarchy, :text
    add_column :eolsnames, :fishbase_hierarchy, :text
  end

  def self.down
    remove_column :eolsnames, :worms_hierarchy
    remove_column :eolsnames, :fishbase_hierarchy
  end
end
