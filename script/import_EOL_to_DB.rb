#!/usr/bin/ruby1.9.1
require 'active_support'
require 'mysql2'
require 'net/http'
require 'uri'
#require 'iconv'

#output_sname = File.new("database_sname.sql", "wb")
#output_cname = File.new("database_cname.sql", "wb")


database = "alexdev"
username = "alexdevuser"
password = "z19Dps5j73T"
socket = "/var/run/mysqld/mysqld.sock"
client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)

  
#client.query("DELETE FROM `eolcnames`;")
query_head = "INSERT INTO `eolsnames` (`id`, `sname`, `taxon`, `data`, `picture`,`created_at`,`updated_at`)\nVALUES\n"
query_head_c = "INSERT INTO `eolcnames` (`eolsname_id`, `cname`, `language`, `eol_preferred`,`created_at`,`updated_at`)\nVALUES\n"


#max_file = 50000
file_start = 8005744 #1300000 #222383#1500000
max_file = 15000001 #222384#

puts "Will be polling EOL between #{file_start.to_s} and #{max_file.to_s}"


line_cname = 0
line_sname = 0

#ic = Iconv.new('UTF-8', 'UTF-8')

filenumber = file_start

while filenumber < max_file do
  print "\rprocessing file #{filenumber}"
  #file = File.new("/var/EOL/EOL/#{filenumber}.json","r")
  begin
    	line = Net::HTTP.get URI.parse("http://www.eol.org/api/pages/1.0/#{filenumber}.json?images=30&common_names=1&details=1") #file.gets
    	if line.match(/^\</).nil? && line.match(/^\{/).nil? then
    	  raise DBTechnicalError.new "file does not start with < or { and is probably empty - SKIPPING IT"
  	  end
  	  if line.match(/worms/i).nil? && line.match(/fishbase/i).nil? then
  	    raise DBTechnicalError.new "no worms or fishbase record, this is not in the sea - Skipping it"
	    end

    	json = JSON.parse(line)

    picture = 0
    if !json["dataObjects"].nil?
      json["dataObjects"].each do |dataset|
        picture = picture+1
        if dataset.to_s.match(/MediaURL/i)
          break  ## we found one image
        end
      end
    end

    ##ADDING SNAME
    if !json["identifier"].nil?
      result = client.query(query_head+"(#{json["identifier"]},'#{json["scientificName"].gsub(/\`/,"").gsub(/'/, "\\\\'")}','#{(json["taxonConcepts"]).to_json}','#{(json["dataObjects"]).to_json}','#{picture.to_s}','2011-08-01 00:03:55','2011-08-01 00:03:55');")#.dump ##dump prevents unescaping
      puts "\rdata added for #{filenumber}"


    else
      raise DBTechnicalError.new "No usable data"
    end

    ##ADDING CNAMES
    if !json["vernacularNames"].nil?
      puts "adding #{json["vernacularNames"].count} Cnames records"
      json["vernacularNames"].each do |cname|
        if cname["eol_preferred"].nil?
          preferred="false"
        else
          preferred="true"
        end
        result = client.query(query_head_c+"(#{json["identifier"]},'#{cname["vernacularName"].gsub(/\`/,"").gsub(/'/, "\\\\'")}','#{cname["language"].gsub(/\`/,"").gsub(/'/, "\\\\'")}',#{preferred},'2011-08-01 00:03:55','2011-08-01 00:03:55');")
      end
    else
      raise DBTechnicalError.new "No usable data"
    end





  rescue
  	#puts "\n>>>>>>>>>>>>>>>incorrect file #{filenumber}<<<<<<<<<<<<<<<<"
  	#puts $!
  end
  #file.close
  filenumber = filenumber + 1

end

