class AddHierarchyIdsToEolsname < ActiveRecord::Migration
  def self.up
    begin
      add_column :eolsnames, :worms_id, :integer
      add_index :eolsnames, :worms_id
      add_column :eolsnames, :fishbase_id, :integer
      add_index :eolsnames, :fishbase_id
    rescue
    end
  end

  def self.down
    remove_column :eolsnames, :worms_id
    remove_column :eolsnames, :fishbase_id
  end
end
