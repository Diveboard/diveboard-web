class AddGlobalTaxonrankToEolsnames < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :taxonrank, :string
    add_column :eolsnames, :parent_id, :string
    add_index :eolsnames, :taxonrank
    add_index :eolsnames, :parent_id
    #Eolsname.find_each {|e| e.update_taxonrank}
    execute("update eolsnames set taxonrank=fishbase_taxonrank where taxonrank is NULL")
    execute("update eolsnames set taxonrank=worms_taxonrank where taxonrank is NULL")
    #Eolsname.find_each {|e| e.update_parent}
    execute("update eolsnames as e1 left join eolsnames as e2 on e1.worms_parent_id = e2.worms_id left join eolsnames as e3 on e1.fishbase_parent_id = e3.fishbase_id set e1.parent_id = IFNULL(e2.id , e3.id)")
  end

  def self.down
    remove_column :eolsnames, :taxonrank
  end
end
