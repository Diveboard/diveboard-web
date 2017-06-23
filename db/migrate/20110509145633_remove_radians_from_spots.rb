class RemoveRadiansFromSpots < ActiveRecord::Migration
  def self.up
    remove_column :spots, :radlat
    remove_column :spots, :radlong
  end

  def self.down
    add_column :spots, :radlat, :float
    add_column :spots, :radlong, :float

    config = Rails::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["database"]
    username = config.database_configuration[RAILS_ENV]["username"]
    password = config.database_configuration[RAILS_ENV]["password"]
    socket = config.database_configuration[RAILS_ENV]["socket"]
  client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
    result = client.query("update `spots` set `radlong` = (`long` * 0.0174532925)")
    result = client.query("update `spots` set `radlat` = (`lat` * 0.0174532925)")

  end
end
