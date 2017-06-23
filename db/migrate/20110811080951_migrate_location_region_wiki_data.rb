class MigrateLocationRegionWikiData < ActiveRecord::Migration
  require 'stringex'
  def self.up
    ## create TWO cool has and belongs to many table for 
    ## country <=> region
    ## location <=> region
     create_table :countries_regions, :id => false do |t|
        t.references :country
        t.references :region
      end
     add_index :countries_regions, [:country_id, :region_id]
     
     create_table :locations_regions, :id => false do |t|
        t.references :location
        t.references :region
      end
      add_index :locations_regions, [:location_id, :region_id]
      
      ## properly link spot to country.... koz integers are better than awkward country codes...
      add_column :spots, :country_id, :integer
      add_column :spots, :blob, :string
      add_index :spots, :country_id

      execute("ALTER IGNORE TABLE countries ADD UNIQUE INDEX(ccode)")## will remove unwanted duplicates      
      add_index :regions, :name, :unique
      add_index :locations, :name
      
      #clean_up the HABTM index...
      ## this does not work and breaks the beautiful (?) HABTM of rails
      #execute("ALTER IGNORE TABLE countries_regions DROP KEY `index_countries_regions_on_country_id_and_region_id`")
      #execute("ALTER IGNORE TABLE countries_regions ADD UNIQUE KEY `index_countries_regions_on_country_id_and_region_id` (`country_id`,`region_id`)")
      #execute("ALTER IGNORE TABLE locations_regions DROP KEY `index_locations_regions_on_location_id_and_region_id`;")
      #execute("ALTER IGNORE TABLE locations_regions ADD UNIQUE KEY `index_locations_regions_on_location_id_and_region_id` (`location_id`,`region_id`);")
      
      
      rename_column :spots, :location, :location_name
      rename_column :spots, :region, :region_name
    
    
      ###
      ### Processing the DB
      ###
      timenow = Time.now.strftime("%Y-%m-%d %H:%M:%S").to_s
      
      config = Rails::Application.instance.config
      database = config.database_configuration[RAILS_ENV]["database"]
      username = config.database_configuration[RAILS_ENV]["username"]
      password = config.database_configuration[RAILS_ENV]["password"]
      socket = config.database_configuration[RAILS_ENV]["socket"]
      client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)
      
      regions = client.query("SELECT DISTINCT `region_name` from `spots` WHERE `region_name` IS NOT NULL AND `region_name` <> '';") 
      locations = client.query("SELECT DISTINCT spots.location_name, countries.id FROM `spots` LEFT JOIN `countries` ON spots.country_code = countries.ccode WHERE `location_name` IS NOT NULL AND `location_name` <> ''") 
      
      create_regions = "INSERT INTO `regions` (`name`, `blob`, `created_at`, `updated_at`) VALUES " 
      regions.each do |r|
        if regions.first != r 
          create_regions += ","
        end
        region_name = r["region_name"]
        create_regions += "(\"#{region_name}\", \"#{region_name.to_url}\", \"#{timenow}\", \"#{timenow}\")"
      end
      create_regions += ";"
      client.query(create_regions)
      
      create_locations = "INSERT INTO `locations` (`name`, `blob`, `country_id`, `created_at`, `updated_at`) VALUES "
      locations.each do |r|
        if locations.first != r
          create_locations += ","
        end
        location_name = r["location_name"]
        id = r["id"]
        create_locations += "(\"#{location_name}\", \"#{location_name.to_url}\", \"#{id}\", \"#{timenow}\", \"#{timenow}\")"
      end
      create_locations += ";"
      client.query(create_locations)
      
      client.query("UPDATE spots,countries SET spots.country_id=countries.id WHERE spots.country_code=countries.ccode")
      client.query("UPDATE spots,locations SET spots.location_id=locations.id WHERE spots.location_name=locations.name")
      client.query("UPDATE spots,regions SET spots.region_id=regions.id WHERE spots.region_name=regions.name")
     
     
     
      
      habtm = client.query("SELECT country_id, location_id, region_id from `spots` WHERE `id` <> 1 AND region_id IS NOT NULL")  
      countries_regions = "INSERT INTO `countries_regions` (`country_id`, `region_id`) VALUES "
      locations_regions = "INSERT INTO `locations_regions` (`location_id`, `region_id`) VALUES "
      habtm.each do |h|
        if h != habtm.first
          countries_regions += ", "
          locations_regions += ", "
        end
        country = h["country_id"]
        region = h["region_id"]
        location = h["location_id"]
        countries_regions += "(\"#{country}\",\"#{region}\")"
        locations_regions += "(\"#{location}\", \"#{region}\")"
      end
      countries_regions += ";"
      locations_regions += ";"
      client.query(countries_regions)
      client.query(locations_regions)
         
      spot = client.query("SELECT id, name from spots")
      #spot_blob = ""
      spot.each do |s|
        id = s["id"]
        name = s["name"].to_url
        q =  "UPDATE spots SET spots.blob=\""+name+"\" where spots.id=#{id};"
        begin
          #puts q
          client.query( q)
        rescue
          puts "******************ERROR******************"
          puts q
        end
      end
      
      #### deduplication
      execute("ALTER IGNORE TABLE countries_regions DROP KEY `index_countries_regions_on_country_id_and_region_id`")
      execute("ALTER IGNORE TABLE countries_regions ADD UNIQUE KEY `index_countries_regions_on_country_id_and_region_id` (`country_id`,`region_id`)")
      execute("ALTER IGNORE TABLE countries_regions DROP KEY `index_countries_regions_on_country_id_and_region_id`")
      execute("ALTER IGNORE TABLE countries_regions ADD KEY `index_countries_regions_on_country_id_and_region_id` (`country_id`,`region_id`)")
      
      execute("ALTER IGNORE TABLE locations_regions DROP KEY `index_locations_regions_on_location_id_and_region_id`")
      execute("ALTER IGNORE TABLE locations_regions ADD UNIQUE KEY `index_locations_regions_on_location_id_and_region_id` (`location_id`,`region_id`)")
      execute("ALTER IGNORE TABLE locations_regions DROP KEY `index_locations_regions_on_location_id_and_region_id`")
      execute("ALTER IGNORE TABLE locations_regions ADD KEY `index_locations_regions_on_location_id_and_region_id` (`location_id`,`region_id`)")
      
      
      
  end

  def self.down
    drop_table :countries_regions
    drop_table :locations_regions
    remove_column :spots, :country_id
    remove_column :spots, :blob
    
  end
end
