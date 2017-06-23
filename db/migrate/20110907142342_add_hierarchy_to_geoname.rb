class AddHierarchyToGeoname < ActiveRecord::Migration
  def self.up
##Will make one single manual import of db content
    if !File.exists?("/tmp/hierarchy.zip")
      system("cd /tmp && wget http://download.geonames.org/export/dump/hierarchy.zip")
    end
    if !File.exists?("/tmp/hierarchy.txt")
      system("cd /tmp && unzip /tmp/hierarchy.zip")
    end
    # create_table :geonames_temp do |t|
    #    t.integer :parent_id
    #    t.integer :child_id
    #    t.string :hierarchy_adm
    #  end
    
    if File.exists?("/tmp/hierarchy.sql")
      system("cd /tmp && rm -rf /tmp/hierarchy.sql")
    end
    File.open("/tmp/hierarchy.sql", 'w') {|f| 
      f.write("SET AUTOCOMMIT=0;")
      counter = 0
      File.open("/tmp/hierarchy.txt", "r") do |infile|
         while (line = infile.gets)
          if (data = line.match(/^([0-9]*)\t([0-9]*)\t(.*)$/))
            parent = data[1]
            child = data[2]
            adm = data[3]
             f.write("UPDATE geonames_cores SET parent_id=#{parent}, hierarchy_adm=\"#{adm}\" WHERE id = #{child};\n")
             counter +=1
             if (counter%20000)==0
               f.write("COMMIT;")
             end
          end
         end
       end
       f.write("COMMIT;")
     }
    
    
    
     config = Rails::Application.instance.config
     database = config.database_configuration[RAILS_ENV]["database"]
     username = config.database_configuration[RAILS_ENV]["username"]
     password = config.database_configuration[RAILS_ENV]["password"]
     #command = "mysql -u#{username} -p#{password} #{database} -e \"LOAD DATA LOCAL INFILE '/tmp/hierarchy.txt' INTO TABLE geonames_temp FIELDS TERMINATED BY '\\t' (parent_id, child_id, hierarchy_adm);\""    
     #puts command
     #system(command)
     #add_index :geonames_temp, :parent_id
     
     command = "mysql -u#{username} -p#{password} #{database} < /tmp/hierarchy.sql"
     puts command
     system(command)
     #execute("UPDATE geonames_cores LEFT JOIN geonames_temp ON geonames_cores.id = geonames_temp.child_id SET geonames_cores.parent_id = geonames_temp.parent_id, geonames_cores.hierarchy_adm = geonames_temp.hierarchy_adm")
     
     #drop_table :geonames_temp
    
  end

  def self.down
  end
end
