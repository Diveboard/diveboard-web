class RenumberDives < ActiveRecord::Migration
  def self.up
    ## This will renumber user from 1 to N and will change the user_id in all dives to match new id
    diverid=1
    config = Rails::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["database"]
    username = config.database_configuration[RAILS_ENV]["username"]
    password = config.database_configuration[RAILS_ENV]["password"]
    socket = config.database_configuration[RAILS_ENV]["socket"]
    client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
  
    User.all.each do |diver|
      result = client.query("update `users` set `id` = #{diverid} where `id` = #{diver.id}")
      diverid += 1
    end
    Dive.all.each do |dive|
      if dive.user_id != nil
        user = User.find_by_fb_id(dive.user_id)
        dive.user_id = user.id
        dive.save
      end
    end
    
    ## move the pictures in user_images to their new id
    User.all.each do |diver|
      if !diver.fb_id.nil? && File.exists?("public/user_images/#{diver.fb_id}.png")
        File.rename("public/user_images/#{diver.fb_id}.png", "public/user_images/#{diver.id}.png")
      end
    end
  end

  def self.down
  end
end
