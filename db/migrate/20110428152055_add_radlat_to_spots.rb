class AddRadlatToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :radlat, :float
    add_column :spots, :radlong, :float
    remove_column :spots, :longitude
    remove_column :spots, :latitude
   # Spot.all.each do |sspot|
   #    sspot.radlat = sspot.lat * 0.0174532925
  #    sspot.radlong = sspot.long * 0.0174532925
   #   sspot.save
  #  end
  
  config = Rails::Application.instance.config
  database = config.database_configuration[RAILS_ENV]["database"]
  username = config.database_configuration[RAILS_ENV]["username"]
  password = config.database_configuration[RAILS_ENV]["password"]
  socket = config.database_configuration[RAILS_ENV]["socket"]
  client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
  result = client.query("update `spots` set `radlong` = (`long` * 0.0174532925)")
  result = client.query("update `spots` set `radlat` = (`lat` * 0.0174532925)")
    
  end

  def self.down
    remove_column :spots, :radlong
    remove_column :spots, :radlat
    add_column :spots, :longitude, :float
    add_column :spots, :latitude, :float
  end
end
