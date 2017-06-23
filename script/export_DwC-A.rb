## This will create a /tmp/gbif.xls file from the v1 Fish database and ftp upload it to OBIS
## This task must be run weekly
require 'cgi'
require 'open-uri'
require 'spreadsheet'
#gem install spreadsheet


##prepare excel sheet with header
header = ["modified", "institutionCode", "references", "catalognumber" ,"scientificnName", "basisOfRecord", "nameAccordingTo", "dateIdentified" ,"bibliographicCitation", "kingdom", "phylum", "class", "order", "family", "genus", "specificEpithet", "infraspecificEpitet", "scientificNameAuthorship", "identifiedBy", "recordedBy", "eventDate", "eventTime", "higherGeographyID", "country", "locality", "decimalLongitude", "decimallatitude", "CoordinatePrecision", "MinimumDepth", "MaximumDepth", "Temperature", "Continent", "waterBody", "eventRemarks", "fieldnotes", "locationRemarks", "type", "language", "rights", "rightsholder", "datasetID", "datasetName", "ownerintitutionCode", "countryCode", "geodeticDatim", "georeferenceSources", "minimumElevationInMeters", "maximumElevationInMeters", "taxonID", "nameAccordingToID", "taxonRankvernacularName", "occurrenceID", "associatedMedia", "eventID", "habitat"]
book = Spreadsheet::Workbook.new
sheet1 = book.create_worksheet
sheet1.name = 'OBIS data'
sheet1.row(0).replace header

line_number = 1

#UPDATE `spots` LEFT JOIN `countries` ON spots.country= countries.ccode SET spots.fullcname = countries.cname
#ActiveRecord::Base.connection.execute("UPDATE dives_eolcnames SET created_at = '#{Date.today.to_s}' WHERE created_at IS NULL")
#ActiveRecord::Base.connection.execute("UPDATE dives_eolcnames SET updated_at = '#{Date.today.to_s}' WHERE updated_at IS NULL")

#Get all the records of the week
#last_week = (Date.today - 7.day).to_s
#records = ActiveRecord::Base.connection.execute("SELECT * FROM dives_eolcnames WHERE created_at >= '#{last_week}'").to_a
records = ActiveRecord::Base.connection.execute("SELECT * FROM dives_eolcnames").to_a

records.each do |record|
  puts "#{record[0]}, #{record[1]}, #{record[2]}"
  
  dive = Dive.find(record[0])
  if record[2].nil?
    sname = Eolsname.find(record[1])
  else
    sname = Eolcname.find(record[2]).eolsname
  end
  ## we have the dive, we have the Eolsname
  wormsid=0
  wormssname=""
  fbid=0
  fbsname=""
  JSON.parse(sname.taxon).each do |taxon|
    #puts sname.taxon
     if taxon["nameAccordingTo"].match(/Worms/i)
     ## We use the WORMS record if we have it
      wormsid= taxon["identifier"].to_i
      wormssname= taxon["scientificName"].to_s
      puts "worms : "+wormsid.to_s+" "+wormssname
     end
     if taxon["nameAccordingTo"].match(/FishBase/i)
     ## We use the WORMS record if we have it
      fbid=taxon["identifier"].to_i
      fbsname=taxon["scientificName"].to_s
      puts "fbase : "+fbid.to_s+" "+fbsname
      
     end
   end
  if wormsid!=0
    speciesID=wormsid
    speciesName = wormssname
    source = "WORMS"
  else
    speciesID=fbid
    speciesName = fbsname
    source = "FishBase"
  end




  
  decimaltime= dive.time_in.hour.to_i + dive.time_in.min.to_i/60
  decimaltimeend = decimaltime + dive.duration/60
  
  case dive.user.sci_privacy
  when 1
    citation = "#{dive.user.full_name.titleize} #{dive.time_in.to_date.to_s} through Diveboard : http://www.diveboard.com"
    collector = "#{dive.user.full_name.titleize}"
    permalink = dive.fullpermalink(:canonical)
    ## We have the name and ID of the species
    record_line = ["#{dive.updated_at.to_time.utc.iso8601}", "Diveboard", "#{permalink}", "#{speciesID}","#{speciesName}", "HumanObservation", "#{source}","#{dive.time_in.to_date.to_s}" ,"", "", "", "", "", "", "", "", "", "", "", "#{collector}", "#{dive.time_in.to_date.to_s}", "#{dive.time_in.utc.iso8601.split("T")[1]}", "#{dive.spot.region.name rescue ""}", "#{dive.spot.country.cname}", "#{dive.spot.location.name rescue ""}", "#{dive.spot.long}", "#{dive.spot.lat}", "100", "0", "#{dive.maxdepth}", "#{dive.temp_bottom.to_s}","", "", "", "", "", "Event", "", "", "Diveboard", "", "", "", "", "EPSG:3857", "Google Maps", "", "", "", "", "", "", "", "", ""]
    sheet1.row(line_number).replace record_line
    line_number += 1
  when 2
    citation = "Anonymous dver #{dive.time_in.to_date.to_s} through Diveboard : http://www.diveboard.com"
    collector = "Anonymous"
    permalink = ""
    ## We have the name and ID of the species
    record_line = ["#{dive.updated_at.to_time.utc.iso8601}", "Diveboard", "#{permalink}","#{speciesID}", "#{speciesName}", "HumanObservation", "#{source}", "#{dive.time_in.to_date.to_s}", "", "", "", "", "", "", "", "", "", "", "", "#{collector}", "#{dive.time_in.to_date.to_s}", "#{dive.time_in.utc.iso8601.split("T")[1]}", "#{dive.spot.region.name rescue ""}", "#{dive.spot.country.cname}", "#{dive.spot.location.name rescue ""}", "#{dive.spot.long}", "#{dive.spot.lat}", "100", "0", "#{dive.maxdepth}", "#{dive.temp_bottom.to_s}", "", "", "", "", "", "Event", "", "", "Diveboard", "", "", "", "", "EPSG:3857", "Google Maps", "", "", "", "", "", "", "", "", ""]
    sheet1.row(line_number).replace record_line
    line_number += 1
  end

end

filename= 'public/diveboard-dwc.xls'

book.write filename
## FTP the file
