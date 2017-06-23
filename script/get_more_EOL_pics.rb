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

###gets the IDS that have photos
ids_to_reprocess = client.query("SELECT id FROM eolsnames WHERE picture > 0")
ids_to_reprocess = ids_to_reprocess.to_a.map{|t| t["id"]}



ids_to_reprocess.each do |filenumber|
  print "\rprocessing file #{filenumber}"
  #file = File.new("/var/EOL/EOL/#{filenumber}.json","r")
  begin
    	line = Net::HTTP.get URI.parse("http://www.eol.org/api/pages/1.0/#{filenumber}.json?images=30&common_names=1&details=1") #file.gets
    	if line.match(/^\</).nil? && line.match(/^\{/).nil? then
    	  raise DBTechnicalError.new "file does not start with < or { and is probably empty - SKIPPING IT"
  	  end
  	  if line.match(/worms/i).nil? && line.match(/fishbase/i).nil? then
  	    raise DBTechnicalError.new "no worms nor fishbase record, this is not in the sea - Skipping it"
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
      #result = client.query(query_head+"(#{json["identifier"]},'#{json["scientificName"].gsub(/\`/,"").gsub(/'/, "\\\\'")}','#{ActiveSupport::JSON.encode(json["taxonConcepts"])}','#{ActiveSupport::JSON.encode(json["dataObjects"])}','#{picture.to_s}','2011-08-01 00:03:55','2011-08-01 00:03:55');")#.dump ##dump prevents unescaping
      data = client.escape((json["dataObjects"]).to_json )
      sql = "UPDATE eolsnames SET eolsnames.data = '#{data}', eolsnames.picture = '#{picture.to_s}' WHERE eolsnames.id = #{filenumber}"
      result = client.query(sql)
      puts "\rdata added for #{filenumber}"

    else
      raise DBTechnicalError.new "No usable data"
    end

  rescue
  	puts "\n>>>>>>>>>>>>>>>incorrect data #{filenumber}<<<<<<<<<<<<<<<<"
  	print sql
  	puts $!
  end

end

