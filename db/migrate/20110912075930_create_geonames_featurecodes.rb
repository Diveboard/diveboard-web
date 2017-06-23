class CreateGeonamesFeaturecodes < ActiveRecord::Migration
  def self.up
    create_table :geonames_featurecodes do |t|
      t.string :feature_code, :limit => 10
      t.string :name
      t.string :description
    end
    
     if !File.exists?("/tmp/featureCodes_en.txt")
        system("cd /tmp && wget http://download.geonames.org/export/dump/featureCodes_en.txt")
      end
      config = Rails::Application.instance.config
      database = config.database_configuration[RAILS_ENV]["database"]
      username = config.database_configuration[RAILS_ENV]["username"]
      password = config.database_configuration[RAILS_ENV]["password"]
      command = "mysql -u#{username} -p#{password} #{database} -e \"LOAD DATA LOCAL INFILE '/tmp/featureCodes_en.txt' INTO TABLE geonames_featurecodes FIELDS TERMINATED BY '\\t' (feature_code, name, description);\""
      puts command
      system(command)
      add_index :geonames_featurecodes, :feature_code
  end

  def self.down
    drop_table :geonames_featurecodes
  end
end
