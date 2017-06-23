#!/usr/bin/ruby1.9.1
require 'active_support'

Eolsname.delete_all


max_file = 1300000
#max_file = 50000
file_start = 1
line_cname = 0
line_sname = 0

filenumber = file_start

ActiveSupport::JSON.backend = 'JSONGem'

records =[]

while filenumber < max_file do
  print "\rprocessing file #{filenumber}"
  file = File.new("/var/EOL/EOL/#{filenumber}.json","r")
  begin
    if (filenumber %10000) == 0
      Eolsname.import records
      records =[]
    end

    	line = file.gets
    	if line.match(/^\</).nil? && line.match(/^\{/).nil? then
    	  raise DBTechnicalError.new "file does not start with < or { and is probably empty - SKIPPING IT"
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
      sname = Eolsname.new do |s|
        s.id = json["identifier"].to_i
        s.sname = json["scientificName"]
        s.taxon = (json["taxonConcepts"]).to_json
        s.data = (json["dataObjects"]).to_json
        s.picture = picture.to_i
      end
      records << sname

    else
      if line.match(/xml/).nil?
        puts "\n>>>>>>>>>>>>>>>incorrect file #{filenumber}<<<<<<<<<<<<<<<<"
      else
        puts "\n#{filenumber} is xml"
      end
    end

  rescue
  	puts "\n>>>>>>>>>>>>>>>incorrect file #{filenumber}<<<<<<<<<<<<<<<<"
  	puts $!
  end
  file.close
  filenumber = filenumber + 1

end

