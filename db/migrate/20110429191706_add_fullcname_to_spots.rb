class AddFullcnameToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :fullcname, :string
    #UPDATE `spots` LEFT JOIN `countries` ON spots.country= countries.ccode SET spots.fullcname = countries.cname
    config = Rails::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["database"]
    username = config.database_configuration[RAILS_ENV]["username"]
    password = config.database_configuration[RAILS_ENV]["password"]
    socket = config.database_configuration[RAILS_ENV]["socket"]
    client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
    result = client.query("UPDATE `spots` LEFT JOIN `countries` ON spots.country= countries.ccode SET spots.fullcname = countries.cname")
    
  end

  def self.down
    remove_column :spots, :fullcname
  end
end
