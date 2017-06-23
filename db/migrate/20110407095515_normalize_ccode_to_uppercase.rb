class NormalizeCcodeToUppercase < ActiveRecord::Migration
  def self.up
    Spot.all.each do |spot|
      spot.location = spot.location.titleize
      spot.country = spot.country.upcase
      spot.name = spot.name.titleize
      if !spot.region.nil? then
        spot.region = spot.region.titleize 
      end
      spot.save
    end
    
    
  end

  def self.down
  end
end
