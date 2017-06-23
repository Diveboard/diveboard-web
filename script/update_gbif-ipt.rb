## updates the gbif_ipt database


##prepare excel sheet with header
header = ["modified", "institutionCode", "references", "catalognumber" ,"scientificnName", "basisOfRecord", "nameAccordingTo", "dateIdentified" ,"bibliographicCitation", "kingdom", "phylum", "class", "order", "family", "genus", "specificEpithet", "infraspecificEpitet", "scientificNameAuthorship", "identifiedBy", "recordedBy", "eventDate", "eventTime", "higherGeographyID", "country", "locality", "decimalLongitude", "decimallatitude", "CoordinatePrecision", "MinimumDepth", "MaximumDepth", "Temperature", "Continent", "waterBody", "eventRemarks", "fieldnotes", "locationRemarks", "type", "language", "rights", "rightsholder", "datasetID", "datasetName", "ownerintitutionCode", "countryCode", "geodeticDatim", "georeferenceSources", "minimumElevationInMeters", "maximumElevationInMeters", "taxonID", "nameAccordingToID", "taxonRankvernacularName", "occurrenceID", "associatedMedia", "eventID", "habitat"]

header_2 = ["modified", "institutionCode", "references", "catalognumber" ,"scientificName", "basisOfRecord", "nameAccordingTo", "dateIdentified" ,"bibliographicCitation", "kingdom", "phylum", "class", "order", "family", "genus", "specificEpithet", "infraspecificEpitet", "scientificNameAuthorship", "identifiedBy", "recordedBy", "eventDate", "eventTime", "higherGeographyID", "country", "locality", "decimalLongitude", "decimallatitude", "CoordinatePrecision", "minimumDepthInMeters", "maximumDepthInMeters", "Temperature", "Continent", "waterBody", "eventRemarks", "fieldnotes", "locationRemarks", "type", "language", "rights", "rightsholder", "datasetID", "datasetName", "ownerinstitutionCode", "countryCode", "geodeticDatim", "georeferenceSources", "minimumElevationInMeters", "maximumElevationInMeters", "taxonID", "nameAccordingToID", "taxonRank", "vernacularName", "occurrenceID", "associatedMedia", "eventID", "habitat"]


# gbif_ipt nmrd6UpGbk9R6l


## used to create the view in the "published" database mapping the real column names
## it will correct typos that happenned on the main DB
=begin
  
  CREATE OR REPLACE VIEW gbif AS
  SELECT
  `g_modified` AS `modified`,
  "Diveboard" AS `institutionCode`,
  "Diveboard" AS `collectionCode`,
  "citizen science scuba dive observation" AS `samplingProtocol`,
  `g_references` AS `references`,
  `g_scientificnName` AS `scientificName`,
  `g_basisOfRecord` AS `basisOfRecord`,
  `g_nameAccordingTo` AS `nameAccordingTo`,
  `g_dateIdentified` AS `dateIdentified`,
  `g_kingdom` AS `kingdom`,
  `g_phylum` AS `phylum`,
  `g_class` AS `class`,
  `g_order` AS `order`,
  `g_family` AS `family`,
  `g_genus` AS `genus`,
  `g_recordedBy` AS `identifiedBy`,
  `g_recordedBy` AS `recordedBy`,
  `g_eventDate` AS `eventDate`,
  `g_higherGeographyID` AS `waterBody`,
  `g_country` AS `country`,
  CONCAT(`g_habitat`, ", ", `g_locality`) AS `verbatimLocality`,
  `g_habitat` AS `locality`,
  `g_decimalLongitude` AS `decimalLongitude`,
  `g_decimallatitude` AS `decimallatitude`,
  `g_CoordinatePrecision` AS `coordinateUncertaintyInMeters`,
  `g_MinimumDepth` AS `minimumDepthInMeters`,
  `g_MaximumDepth` AS `maximumDepthInMeters`,
  `g_Temperature` AS `Temperature`,
  `g_eventRemarks` AS `eventRemarks`,
  `g_fieldnotes` AS `fieldnotes`,
  `g_locationRemarks` AS `locationRemarks`,
  `g_type` AS `type`,
  `g_language` AS `language`,
  `g_rights` AS `rights`,
  `g_rightsholder` AS `rightsholder`,
  `g_datasetID` AS `datasetID`,
  `g_datasetName` AS `datasetName`,
  "Diveboard" AS `ownerinstitutionCode`,
  `g_countryCode` AS `countryCode`,
  `g_geodeticDatim` AS `geodeticDatum`,
  `g_georeferenceSources` AS `georeferenceSources`,
  `g_minimumElevationInMeters` AS `minimumElevationInMeters`,
  `g_maximumElevationInMeters` AS `maximumElevationInMeters`,
  `g_taxonRankvernacularName` AS `taxonRank`,  
  `g_nameAccordingToID` AS `taxonID`,
  `g_occurrenceID` AS `occurrenceID`,
  `g_occurrenceID` AS `catalogNumber`,
  `g_associatedMedia` AS `associatedMedia`,
  `g_eventID` AS `eventID`,
  `g_eventID` AS `habitat`
  from diveboard.gbif_ipts;

=end






## STEP 1 REMOVE records that don't exist anymore

GbifIpt.all.each do |e|
  e.destroy unless e.exists?
end

#"DELETE * FROM table_name"


## STEP 2 UPDATE ALL FIELDS


records = ActiveRecord::Base.connection.execute("SELECT * FROM dives_eolcnames").to_a

records.each do |record|
  #puts "#{record[0]}, #{record[1]}, #{record[2]}"
  begin
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
        #puts "worms : "+wormsid.to_s+" "+wormssname
       end
       if taxon["nameAccordingTo"].match(/FishBase/i)
       ## We use the WORMS record if we have it
        fbid=taxon["identifier"].to_i
        fbsname=taxon["scientificName"].to_s
        #puts "fbase : "+fbid.to_s+" "+fbsname
        
       end
     end

    speciesName = sname.sname

    if dive.spot.country.ccode == "BLANK"
      dccode = ""
    else
      dccode = dive.spot.country.ccode
    end



  
    decimaltime= dive.time_in.hour.to_i + dive.time_in.min.to_i/60
    decimaltimeend = decimaltime + dive.duration/60
    
    case dive.user.sci_privacy
    when 1
      citation = "#{dive.user.full_name.titleize} #{dive.time_in.to_date.to_s} through Diveboard : http://www.diveboard.com"
      collector = "#{dive.user.full_name.titleize}"
      #Name of the Diver| eventDate|through: references =>  dimibrosens|2013-07-05|through: http://www.diveboard.com/dimibrosens/D1PROVr 
      bib_citation = "#{dive.user.nickname}|#{dive.time_in.to_date.to_s}|#{dive.fullpermalink(:canonical)}"
      permalink = dive.fullpermalink(:canonical)
      ## We have the name and ID of the species
      record_line = ["#{dive.updated_at.to_time.utc.iso8601}", "Diveboard", "#{permalink}", "EOL:#{sname.id}","#{speciesName}", "HumanObservation", "EOL","#{dive.time_in.to_date.to_s}" ,"#{bib_citation}", "#{sname.find_ancestor_with_rank("kingdom").sname rescue "" }", "#{sname.find_ancestor_with_rank("phylum").sname rescue "" }", "#{sname.find_ancestor_with_rank("class").sname rescue "" }", "#{sname.find_ancestor_with_rank("order").sname rescue "" }", "#{sname.find_ancestor_with_rank("family").sname rescue "" }", "#{sname.find_ancestor_with_rank("genus").sname rescue "" }", "", "", "", "", "#{collector}", "#{dive.time_in.strftime("%Y-%m-%dT%TZ")}", "#{dive.time_in.utc.iso8601.split("T")[1]}", "#{dive.spot.region.name rescue ""}", "#{dive.spot.country.cname}", "#{dive.spot.location.name rescue ""}", "#{dive.spot.long}", "#{dive.spot.lat}", "100", "0", "#{dive.maxdepth}", "#{dive.temp_bottom.to_s}","", "", "", "", "", "Event", "", "http://creativecommons.org/publicdomain/zero/1.0/", "Diveboard", "http://ipt.diveboard.com/resource.do?r=diveboard-occurrences", "Diveboard - Scuba diving citizen science", "DIVEBOARD", "#{dccode}", "EPSG:3857", "Google Maps", "#{dive.altitude || 0}", "#{dive.altitude || 0}", "", "http://eol.org/pages/#{sname.id}", "#{sname.taxonrank}", "diveboard:#{record[0]}_#{record[1] || 0}_#{record[2] || 0}", "", "", "#{dive.spot.name}"]
    when 2
      citation = "Anonymous dver #{dive.time_in.to_date.to_s} through Diveboard : http://www.diveboard.com"
      collector = "Anonymous"
      permalink = ""
      bib_citation = ""
      ## We have the name and ID of the species
      record_line = ["#{dive.updated_at.to_time.utc.iso8601}", "Diveboard", "#{permalink}","EOL:#{sname.id}", "#{speciesName}", "HumanObservation", "EOL", "#{dive.time_in.to_date.to_s}", "#{bib_citation}", "#{sname.find_ancestor_with_rank("kingdom").sname rescue "" }", "#{sname.find_ancestor_with_rank("phylum").sname rescue "" }", "#{sname.find_ancestor_with_rank("class").sname rescue "" }", "#{sname.find_ancestor_with_rank("order").sname rescue "" }", "#{sname.find_ancestor_with_rank("family").sname rescue "" }", "#{sname.find_ancestor_with_rank("genus").sname rescue "" }", "", "", "", "", "#{collector}", "#{dive.time_in.strftime("%Y-%m-%dT%TZ")}", "#{dive.time_in.utc.iso8601.split("T")[1]}", "#{dive.spot.region.name rescue ""}", "#{dive.spot.country.cname}", "#{dive.spot.location.name rescue ""}", "#{dive.spot.long}", "#{dive.spot.lat}", "100", "0", "#{dive.maxdepth}", "#{dive.temp_bottom.to_s}", "", "", "", "", "", "Event", "", "http://creativecommons.org/publicdomain/zero/1.0/", "Diveboard", "http://ipt.diveboard.com/resource.do?r=diveboard-occurrences", "Diveboard - Scuba diving citizen science", "DIVEBOARD", "#{dccode}", "EPSG:3857", "Google Maps", "#{dive.altitude || 0}", "#{dive.altitude || 0}", "", "http://eol.org/pages/#{sname.id}", "#{sname.taxonrank}", "diveboard:#{record[0]}_#{record[1] || 0}_#{record[2] || 0}", "", "", "#{dive.spot.name}"]
    else
      ##user does not want to share
      record_line = nil
    end

      ## add record line to database
    entry = GbifIpt.where(:dive_id => dive.id).where(:eol_id => sname.id)
    if entry.blank?
      entry = GbifIpt.new
      entry.upd_attr "dive_id", dive.id 
      entry.upd_attr "eol_id", sname.id
    else
      if entry.count > 1
        entry[1..-1].each {|e| e.destroy}
      end
      entry = entry.first
    end


      if !record_line.nil?
      header.each_with_index { |h,i|
        begin
          entry.upd_attr("g_#{h}", record_line[i])
        rescue
          puts "failed to update attr #{i} column #{h}"
          puts record_line
          puts $!.message
        end
      }
      entry.save
    end

  rescue
    puts "missign entry "+$!.message
  end



end



