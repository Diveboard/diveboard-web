require "iconv"
require "cgi"
require "i18n"

counter = 1

file = File.new("script/gbif_taxo_db_full_03_2011.txt","r")
#file = File.new("script/gbif_test.txt","r")
filo = File.new("script/gbif_taxo_db_full_03_2011.sql","w")


filo.puts 'DROP TABLE IF EXISTS `fishes`;'
filo.puts '/*!40101 SET @saved_cs_client     = @@character_set_client */;'
filo.puts '/*!40101 SET character_set_client = utf8 */;'
filo.puts 'CREATE TABLE `fishes` ('
filo.puts '  `id` int(11) NOT NULL AUTO_INCREMENT,'
filo.puts '  `name` varchar(255) DEFAULT NULL,'
filo.puts '  `created_at` datetime DEFAULT NULL,'
filo.puts '  `updated_at` datetime DEFAULT NULL,'
filo.puts '  `taxonomy_id` int(11) DEFAULT NULL,'
filo.puts '  `preferred` tinyint(1) DEFAULT NULL,'
filo.puts '  `scientific_name` varchar(255) DEFAULT NULL,'
filo.puts '  PRIMARY KEY (`id`)'
filo.puts ') ENGINE=InnoDB AUTO_INCREMENT=1096252 DEFAULT CHARSET=utf8;'
filo.puts '/*!40101 SET character_set_client = @saved_cs_client */;'
filo.puts '--'
filo.puts '-- Dumping data for table `fishes`'
filo.puts '--'
filo.puts 'LOCK TABLES `fishes` WRITE;'
filo.puts '/*!40000 ALTER TABLE `fishes` DISABLE KEYS */;'

filo.write 'INSERT INTO `fishes` VALUES '
index = 0

while (line = file.gets)
  if index != 0 
    then 
    filo.write "," 
    end
  index += 1
  begin
    if !line.valid_encoding?
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      line = ic.iconv(line)
    end
    
    #escape ' into \'
    line= line.gsub(/'/, "\\\\'")
    
    if line[-1,1] == "\n"
      fields = line.chop.split(/\t/)
    else
      fields = line.split(/\t/)
    end
    tax_id = fields[0].to_i
    sci_name = CGI::unescapeHTML fields[1]
    #ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    #sci_name = ic.iconv(sci_name + ' ')[0..-2]
    #
    if fields[2].nil?
      c_name = ""
    else
      c_name = CGI::unescapeHTML fields[2]
    end
   # if Fish.where("taxonomy_id = ? AND scientific_name = ? AND name  = ? ", tax_id, sci_name, c_name).empty?   
  #    step = 7
   #   new_fish = Fish.new
    #  step = 8
     # new_fish.scientific_name = sci_name
    #  step = 9
     # new_fish.name = c_name
    #  step = 10
    #  new_fish.taxonomy_id = tax_id
    #  step = 11
    #  new_fish.save
      #puts "added #{sci_name} #{tax_id}  #{c_name}    (id: #{new_fish.id})"
      filo.write "(#{index},'#{c_name}','2011-03-31 20:03:55','2011-03-31 20:03:55',#{tax_id},NULL,'#{sci_name}')"
    
    #end
  rescue => e
    puts ">>>>>>>>>>> NEW ERROR <<<<<<<<<<<<<<"
    puts $!
    puts "Failed to add  #{sci_name} #{tax_id}  #{c_name} (id: #{index})\n" 
    puts "=============================="
    puts e.exception
    puts e.backtrace
  end
end
file.close
filo.puts ";"
filo.close

puts "we now need to do MANUALLY : mysql --max_allowed_packet=500M  --user='dbuser' --password='VZfs591bnw32d' --default-character-set=utf8 diveboard < gbif_taxo_db_full_03_2011.sql"
puts " then remove duplicates : "
puts "ALTER IGNORE TABLE `fishes` ADD UNIQUE INDEX(`taxonomy_id`, `name`, `scientific_name`);"
