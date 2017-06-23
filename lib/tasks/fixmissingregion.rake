namespace :fixmissingregion do

	task :add_linking_regions_geonamescore => :environment do
		regions = Region.all
		failed = []
		successed = []
		regions.each do |r|
			puts "#{r.id} is being processed"
			if !r.name.include?("/") && !r.name.include?("---") && r.name != "-"
				geonames_core = GeonamesCore.search(r.name, :with => { :h =>true }).first
				if geonames_core.nil?
					failed.push r
				else
					r.geonames_core_id = geonames_core.id
					r.save!
					successed.push r
				end
			end
		end
		File.open("tmp/output", "w") do |f|
			successed.each do |s| 
    			f.write "we succeed to add id on : #{s.id} \n"
    		end
    		
    		f.write "\n \n"

    		failed.each do |i|
				f.write "We have an issu on region with id #{i.id}\n"
			end
		end
	end

	task :upgrade_spot_region_id => :environment do 
		spots = Spot.where("region_id is null and spots.lat!=0 and spots.long!=0")
		step = 0.01
		spot=nil
		spots.each do |s|
			puts "start work on #{s.id}"
		    minLat = s.lat
		    minLng = s.long
		    maxLat = s.lat
		    maxLng = s.long
    		until spot != nil
		      minLat -= step
		      minLng -= step
		      maxLat += step
		      maxLng += step
		      spot = Spot.where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) and region_id is not null", minLat, maxLat, minLng, maxLng).first
		  	end
		  	dlon = spot.long - s.long 
			dlat = spot.lat - s.lat 
			a = (Math.sin(dlat/2)) ** 2 + Math.cos(spot.lat) * Math.cos(s.lat) * (Math.sin(dlon/2)) ** 2 
			c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a) ) 
			d = 6378 * c
			puts "distance #{d} from #{s.id} to #{spot.id}" #> "tmp/spot_update"
		  	s.region_id=spot.region_id
		 	s.save!
		 	spot=nil
		end
	end

	task :upgrade_spot_country_id => :environment do 
		spots = Spot.where("country_id is null and spots.lat!=0 and spots.long!=0")
		step = 0.01
		spot=nil
		spots.each do |s|
			puts "start work on #{s.id}"
		    minLat = s.lat
		    minLng = s.long
		    maxLat = s.lat
		    maxLng = s.long
    		until spot != nil
		      minLat -= step
		      minLng -= step
		      maxLat += step
		      maxLng += step
		      spot = Spot.where("(spots.lat BETWEEN ? AND ?) AND (spots.long BETWEEN ? AND ?) and country_id is not null", minLat, maxLat, minLng, maxLng).first
		  	end
		  	dlon = spot.long - s.long 
			dlat = spot.lat - s.lat 
			a = (Math.sin(dlat/2)) ** 2 + Math.cos(spot.lat) * Math.cos(s.lat) * (Math.sin(dlon/2)) ** 2 
			c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a) ) 
			d = 6378 * c
			puts "distance #{d} from #{s.id} to #{spot.id}" #> "tmp/spot_update"
		  	s.country_id=spot.country_id
		 	s.save!
		 	spot=nil
		end
	end
end
