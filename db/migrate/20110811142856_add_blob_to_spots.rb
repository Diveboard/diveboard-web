class AddBlobToSpots < ActiveRecord::Migration
  #### MOVED BACK TO "migrate_location..."
  
  def self.up
    #add_column :spots, :blob, :string
    #Spot.all.each do |spot|
    #  spot.blob = spot.name.to_url
    #  spot.save
    #end
  end

  def self.down
    #remove_column :spots, :blob
  end
end
