#!/usr/bin/ruby1.9.1
require 'active_support'
require 'mysql2'
require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'json'

database = "diveboard"
username = "dbuser"
password = ENV["PROD_DB"]
client = Mysql2::Client.new(:database => database, :username => username, :password => password, :host => "localhost")

puts client

###gets the IDS that have photos
ids_to_reprocess = client.query("SELECT sname,id FROM eolsnames")
#ids_to_reprocess = ids_to_reprocess.to_a.map{|t| t["id"]}

failed_ids=[]

def process_id(id, sname, client)
  encoded_sname = URI.encode_www_form_component(sname)

  sql = ""
  print "\r\e[0K"
  print "\rprocessing id #{id}"
    data = open("https://eol.org/api/search/1.0.json?q=#{encoded_sname}&exact=1")
    jsondata = JSON.parse(data.read)
    new_id = jsondata["results"][0]["id"]
    print " new id: #{new_id}"

    doc = Nokogiri::HTML(open("https://eol.org/pages/#{new_id}"))
    begin
      thumbnail_href = doc.css("a.hero-link img")[0]["src"]
      throw if thumbnail_href.nil?
      sql = "UPDATE eolsnames SET eolsnames.picture = '1', eolsnames.thumbnail_href = '#{thumbnail_href}', eol_id = '#{new_id}' WHERE eolsnames.id = #{id}"
    rescue
      sql = "UPDATE eolsnames SET eolsnames.picture = '0', eolsnames.thumbnail_href = NULL, eol_id = '#{new_id}' WHERE eolsnames.id = #{id}"
    end
    result = client.query(sql)
end



ids_to_reprocess.to_a.each do |entry|
   begin
     process_id(entry["id"], entry["sname"], client)
     sleep 0.1
   rescue
     failed_ids.push(entry["id"])
     puts("Failed to process #{entry["id"]}")
   end
end
failed_ids

