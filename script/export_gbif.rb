## This will create a /tmp/gbif.xls file from the v1 Fish database and ftp upload it to OBIS
## This task must be run weekly
require 'cgi'
require 'open-uri'
require 'spreadsheet'
#gem install spreadsheet


##prepare excel sheet with header
header = ["DateLastModified", "Institutioncode", "CollectionCode", "CatalogNumber", "RecordURL", "RecordID" ,"ScientificName", "BasisOfRecord", "Source", "Citation", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Subgenus", "Species", "Subspecies", "ScientificNameAuthor", "IdentifiedBy", "YearIdentified", "MonthIdentified", "DayIdentified", "TypeStatus", "CollectorNumber", "Field Number", "Collector", "StartYearCollected", "StartMonthCollected", "StartDayCollected", "EndYearCollected", "EndMonthCollected", "EndDayCollected", "YearCollected", "MonthCollected", "DayCollected", "JulianDay", "StartJulianDay", "EndJulianDay", "TimeOfDay", "StartTimeOfDay", "EndTimeOfDay", "TimeZone", "ContinentOcean", "Country", "StateProvince", "County", "Locality", "Longitude", "StartLongitude", "EndLongitude", "Latitude", "StartLatitude", "EndLatitude", "CoordinatePrecision", "MinimumDepth", "MaximumDepth", "DepthRange", "Temperature", "Sex", "LifeStage", "PreparationType", "IndividualCount", "ObservedIndividualCount", "ObservedWeight", "PreviousCatalogNumber", "RelationshipType", "RelatedCatalogItem", "Notes"]
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
    citation = "#{dive.user.full_name.titleize} #{dive.time_in.to_date.to_s} through Diveboard : https://www.diveboard.com"
    collector = "#{dive.user.full_name.titleize} - Diveboard"
    permalink = dive.fullpermalink(:canonical)
    ## We have the name and ID of the species
    record_line = ["#{dive.updated_at.to_s}", "DIVEBOARD", "","" , "#{permalink}", "#{speciesID}","#{speciesName}", "o", "#{source}", "#{citation}", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "#{collector}", "", "", "", "", "", "", "#{dive.time_in.to_date.year.to_s}", "#{dive.time_in.to_date.month.to_s}", "#{dive.time_in.to_date.day.to_s}", "", "", "", "", "#{decimaltime}", "#{decimaltimeend}", "", "#{dive.spot.region}", "#{dive.spot.country.cname}", "", "", "#{dive.spot.location}", "#{dive.spot.long}", "", "", "#{dive.spot.lat}", "", "", "100", "0", "#{dive.maxdepth}", "", "#{dive.temp_bottom.to_s}", "", "", "", "", "", "", "", "", "", ""]
    sheet1.row(line_number).replace record_line
    line_number += 1
  when 2
    citation = "Anonymous dver #{dive.time_in.to_date.to_s} through Diveboard : https://www.diveboard.com"
    collector = "Anonymous - Diveboard"
    permalink = ""
    ## We have the name and ID of the species
    record_line = ["#{dive.updated_at.to_s}", "DIVEBOARD", "","" , "#{permalink}","#{speciesID}", "#{speciesName}", "o", "#{source}", "#{citation}", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "#{collector}", "", "", "", "", "", "", "#{dive.time_in.to_date.year.to_s}", "#{dive.time_in.to_date.month.to_s}", "#{dive.time_in.to_date.day.to_s}", "", "", "", "", "#{decimaltime}", "#{decimaltimeend}", "", "#{dive.spot.region}", "#{dive.spot.country.cname}", "StateProvince", "County", "#{dive.spot.location}", "#{dive.spot.long}", "", "", "#{dive.spot.lat}", "", "", "100", "0", "#{dive.maxdepth}", "DepthRange", "#{dive.temp_bottom.to_s}", "", "", "", "", "", "", "", "", "", ""]
    sheet1.row(line_number).replace record_line
    line_number += 1
  end
  
  
  
  
  


end

filename= '/tmp/diveboard-obis-'+Date.today.to_s+'.xls'

book.write filename
## FTP the file


host = "ftp.marine.rutgers.edu"
location = "." 
login = "stafford"
pwd = "beeky624"

%x[/usr/bin/ncftpput -u #{login} -p #{pwd} #{host} #{location} #{filename}] 
