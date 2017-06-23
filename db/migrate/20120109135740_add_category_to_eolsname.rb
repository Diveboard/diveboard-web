class AddCategoryToEolsname < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :category, :string
    add_index :eolsnames, :category
    ## to fill the db:
    #Eolsname.all.each do |e|
    #  e.category = e.lookup_category
    #  e.save
    #end
  end

  def self.down
    remove_column :eolsnames, :category
  end
end
