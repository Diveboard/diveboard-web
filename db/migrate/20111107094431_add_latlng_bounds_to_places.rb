class AddLatlngBoundsToPlaces < ActiveRecord::Migration
  def self.up
    
    ## create columns
    add_column :countries, :nesw_bounds, :string
    add_column :locations, :nesw_bounds, :string
    add_column :regions, :nesw_bounds, :string
    
    
    
    
    
  end

  def self.down
    remove_column :countries, :nesw_bounds
    remove_column :locations, :nesw_bounds
    remove_column :regions, :nesw_bounds
  end
end
