#!/usr/bin/ruby1.9.1
require 'active_support'
require 'mysql2'
require 'net/http'
require 'uri'
#require 'iconv'
require 'open-uri'
require 'nokogiri'

#output_sname = File.new("database_sname.sql", "wb")
#output_cname = File.new("database_cname.sql", "wb")


database = "diveboard"
username = "dbuser"
password = ENV["PROD_DB"]
socket = "/var/run/mysqld/mysqld.sock"
client = Mysql2::Client.new(:database => database, :username => username, :password => password, :socket => socket)

###gets the IDS that have photos
ids_to_reprocess = client.query("SELECT sname,id FROM eolsnames")
#ids_to_reprocess = ids_to_reprocess.to_a.map{|t| t["id"]}



ids_to_reprocess.to_a.each do |entry|
  id = entry["id"]
  sname = entry["sname"]
  sql = ""
  print "\rprocessing id #{id}"
  begin
    data = open("https://eol.org/api/search/1.0.json?q=#{sname.gsub(/ /, "%20")}&exact=1")
    jsondata = JSON.parse(data.read)
    new_id = jsondata["results"][0]["id"]


    doc = Nokogiri::HTML(open("https://eol.org/pages/#{new_id}"))
    begin
      thumbnail_href = doc.css("a.hero-link img")[0]["src"]
      throw if thumbnail_href.nil?
      sql = "UPDATE eolsnames SET eolsnames.picture = '1', eolsnames.thumbnail_href = '#{thumbnail_href}' WHERE eolsnames.id = #{id}"
    rescue
      sql = "UPDATE eolsnames SET eolsnames.picture = '0', eolsnames.thumbnail_href = NULL WHERE eolsnames.id = #{id}"
    end
    result = client.query(sql)
    sleep 0.25
  rescue
  	puts "\n>>>>>>>>>>>>>>>incorrect data #{id}<<<<<<<<<<<<<<<<"
  	print sql
  	puts $!
  end

end

