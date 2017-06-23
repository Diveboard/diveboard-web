#!/usr/bin/ruby1.9.1
require 'net/http'
require 'uri'
#require 'iconv'

#output_sname = File.new("database_sname.sql", "wb")
#output_cname = File.new("database_cname.sql", "wb")

if ARGV[0].blank?
  start = 0
else
  start = ARGV[0].to_i
end

Eolsname.all.each do |species|
  ##PUTS THE IDs
  if species.id > start
    taxon = JSON.parse(species.taxon)
    taxon.each do |entry|
      if entry["nameAccordingTo"].match(/worms/i)
        #this is a worms entry
        species.worms_id = entry["identifier"].to_i
      elsif entry["nameAccordingTo"].match(/fishbase/i)
        species.fishbase_id = entry["identifier"].to_i
      end
    end
    puts "\rProcessing record #{species.id}"
    species.save
  
  
    ##GETS Hierarchy infos
    species.update_hierarchy
  end
end

