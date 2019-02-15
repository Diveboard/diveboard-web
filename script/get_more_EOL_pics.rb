#!/usr/bin/ruby1.9.1
require 'active_support'
require 'mysql2'
require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'

#require 'iconv'

#output_sname = File.new("database_sname.sql", "wb")
#output_cname = File.new("database_cname.sql", "wb")


database = "alexdev"
username = "alexdevuser"
password = "z19Dps5j73T"
socket = "/var/run/mysqld/mysqld.sock"
client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)

###gets the IDS that have photos
ids_to_reprocess = client.query("SELECT id FROM eolsnames")
ids_to_reprocess = ids_to_reprocess.to_a.map{|t| t["id"]}



ids_to_reprocess.each do |id|
  print "\rprocessing species #{id}"
  #file = File.new("/var/EOL/EOL/#{filenumber}.json","r")
  begin
    doc = Nokogiri::HTML(open("https://eol.org/pages/#{filenumber}"))
    thumbnail_href = doc.css("a.hero-link img")[0]["src"]

    sql = "UPDATE eolsnames SET eolsnames.picture = '1', eolsname.thumbnail_href = '#{thumbnail_href}' WHERE eolsnames.id = #{id}"
    
    else
      raise DBTechnicalError.new "No usable data"
    end

  rescue
  	puts "\n>>>>>>>>>>>>>>>incorrect data #{filenumber}<<<<<<<<<<<<<<<<"
  	print sql
  	puts $!
  end

end

