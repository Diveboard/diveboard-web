class AddCountryToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :country, :string
    #update the seed record

    
  end

  def self.down
    remove_column :spots, :country
  end
end
