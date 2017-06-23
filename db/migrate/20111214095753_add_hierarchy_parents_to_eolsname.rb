class AddHierarchyParentsToEolsname < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :worms_parent_id, :integer
    add_index :eolsnames, :worms_parent_id
    add_column :eolsnames, :fishbase_parent_id, :integer
    add_index :eolsnames, :fishbase_parent_id
    add_column :eolsnames, :worms_taxonrank, "ENUM('life', 'domain', 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')"
    add_index :eolsnames, :worms_taxonrank
    add_column :eolsnames, :fishbase_taxonrank, "ENUM('life', 'domain', 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')"
    add_index :eolsnames, :fishbase_taxonrank
    
  end

  def self.down
      remove_column :eolsnames, :worms_parent_id
      remove_column :eolsnames, :fishbase_parent_id
      remove_column :eolsnames, :worms_taxonrank
      remove_column :eolsnames, :fishbase_taxonrank
  end
end
