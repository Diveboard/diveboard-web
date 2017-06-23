class AddPressureToSettings < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
       ## add pressure to units
       
       if !user.settings.nil?
         settings = JSON.parse(user.settings)
         if settings["units"].nil? || settings["units"].empty?
           settings["units"] = {"distance" => "Km", "weight" => "Kg", "temperature" => "C", "pressure" => "bar" }
         else
           settings["units"]["pressure"]="bar" 
         end
         user.settings = settings.to_json
         user.save
       end
         
     end
  end

  def self.down
  end
end
