class CreateGeonamesCores < ActiveRecord::Migration
  #The main 'geoname' table has the following fields :
  #---------------------------------------------------
  #geonameid         : integer id of record in geonames database
  #name              : name of geographical point (utf8) varchar(200)
  #asciiname         : name of geographical point in plain ascii characters, varchar(200)
  #alternatenames    : alternatenames, comma separated varchar(5000)
  #latitude          : latitude in decimal degrees (wgs84)
  #longitude         : longitude in decimal degrees (wgs84)
  #feature class     : see http://www.geonames.org/export/codes.html, char(1)
  #feature code      : see http://www.geonames.org/export/codes.html, varchar(10)
  #country code      : ISO-3166 2-letter country code, 2 characters
  #cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 60 characters
  #admin1 code       : fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
  #admin2 code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
  #admin3 code       : code for third level administrative division, varchar(20)
  #admin4 code       : code for fourth level administrative division, varchar(20)
  #population        : bigint (8 byte int) 
  #elevation         : in meters, integer
  #gtopo30           : average elevation of 30'x30' (ca 900mx900m) area in meters, integer
  #timezone          : the timezone id (see file timeZone.txt)
  #modification date : date of last modification in yyyy-MM-dd format
  
  
  
  def self.up
    create_table :geonames_cores do |t|
    #create_table :geonames_cores, :id => false do |t|
      #t.integer :id
      t.string :name, :limit => 200
      t.string :asciiname, :limit => 200
      t.string :alternatenames, :limit => 5000
      t.column :latitude, "double precision"
      t.column :longitude, "double precision"
      t.string :feature_class, :limit => 1
      t.string :feature_code, :limit => 10
      t.string :country_code, :limit => 5
      t.string :cc2, :limit =>60
      t.string :admin1_code, :limit => 20
      t.string :admin2_code, :limit => 80
      t.string :admin3_code, :limit => 20
      t.string :admin4_code, :limit => 20
      t.column :population, "BIGINT UNSIGNED"
      t.integer :elevation
      t.integer :gtopo30
      t.string :timezone_id
      t.date :updated_at
      t.integer :parent_id
      t.string :hierarchy_adm
    end
    ## populate the db


    #add_index :geonames_cores, :id
    add_index :geonames_cores, :feature_class
    #add_index :geonames_cores, :name
    add_index :geonames_cores, [:latitude, :longitude]
    add_index :geonames_cores, :feature_code
    add_index :geonames_cores, :country_code
    #add_index :geonames_cores, :cc2
    #add_index :geonames_cores, :admin1_code
    #add_index :geonames_cores, :admin2_code
    #add_index :geonames_cores, :admin3_code
    #add_index :geonames_cores, :admin4_code
    add_index :geonames_cores, :parent_id
    #add_index :geonames_cores, :hierarchy_adm
    
    if !File.exists?("/tmp/allCountries.zip")
      system("cd /tmp && rm -rf allCountries.* && wget http://download.geonames.org/export/dump/allCountries.zip")
    end
    if !File.exists?("/tmp/allCountries.txt")
      system("cd /tmp && unzip allCountries.zip")
    end
    config = Rails::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["database"]
    username = config.database_configuration[RAILS_ENV]["username"]
    password = config.database_configuration[RAILS_ENV]["password"]
    command = "mysql -u#{username} -p#{password} #{database} -e \"SET UNIQUE_CHECKS=0; set autocommit = 0; LOAD DATA LOCAL INFILE '/tmp/allCountries.txt' INTO TABLE geonames_cores FIELDS TERMINATED BY '\\t' (id, name, asciiname, alternatenames, latitude, longitude, feature_class, feature_code, country_code, cc2, admin1_code, admin2_code, admin3_code, admin4_code, population, elevation, gtopo30, timezone_id, updated_at); commit;\""
    puts command
    system(command)
    

    
  end

  def self.down
    drop_table :geonames_cores
  end
end
