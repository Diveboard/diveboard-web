namespace :area_detection do

	step = 0.2

	desc "Calculate shop density on world map"
	task :calculate => :environment do
		ShopDensity.delete_all
		ActiveRecord::Base.connection.execute('ALTER TABLE shop_densities AUTO_INCREMENT = 1')
		puts "Start calculating shop density"
		lng = -180.0
		lat = 90.0
		percent = 0.0
		step_pt = 100.0 / ((180.0*60.0)/(step*60.0))

		while lat > -90 do
			print "\rProcessing density calculation #{percent.to_i}%"
			shop = Shop.where(lat: (lat - step)..lat).where("lat is not null and lng is not null").order("lng ASC")
			if shop.size != 0
				first_lng = shop.first.lng
				while lng < first_lng do
					lng += step
				end
				lng -= step
				i = 0
				while shop[i] do
					count_shop = 0
					count_dive = 0
					while shop[i] && shop[i].lng >= lng && shop[i].lng < lng + step do
						count_shop += 1
						count_dive += shop[i].dive_ids.size
						i += 1
					end
					if count_shop != 0
						density = ShopDensity.create(minLat: (lat - step), maxLat: lat, minLng: lng, maxLng: (lng + step), shop_density: count_shop, dive_density: count_dive)
						density.save
					end
					lng += step
				end
			end
			lat -= step
			lng = -180
			percent += step_pt
		end
		puts "\rProcessing density calculation 100%"
	end

	# Lat 90
	# Lng -180
	task :aggregate => :environment do
		Area.delete_all
		ActiveRecord::Base.connection.execute('ALTER TABLE areas AUTO_INCREMENT = 1')
		percent = 0.0
		init_rest = 1


		puts "Start aggregating areas"
		puts "Retrieving densities data"
		shops = ShopDensity.where("shop_density >= 4").order("maxLat DESC, minLng ASC")
		total_shops = shops.size
		while shops.size != 0 do
			print "\rProcessing aggregation #{(100.0 - ((shops.size * 100.0) / total_shops)).to_i}%"
			maxLat = shops.first.maxLat
			minLng = shops.first.minLng
			minLat = shops.first.minLat - step
			maxLng = shops.first.maxLng + step
			shops.delete_at(0)
			found_flag = 1
			rest = init_rest

			while found_flag == 1 do
				found_flag = 0
				shops.delete_if do |shop|
					if shop.maxLat <= maxLat && shop.maxLat >= minLat && shop.minLng >= minLng && shop.minLng <= maxLng
						found_flag = 1
						true
					else
						false
					end
				end
				if found_flag == 1
					minLat -= step
					maxLng += step
					rest = init_rest
				elsif rest != 0
					rest -= 1
					found_flag = 1
				end
			end
			minLat += step
			maxLng -= step
			geoname = GeonamesCore.where("(latitude BETWEEN ? AND ?) AND (longitude BETWEEN ? AND ?) AND feature_class = ?", minLat, maxLat, minLng, maxLng, "P").order("population DESC").limit(1).first
			if !(minLat.to_i == 0 && minLng.to_i == 0 && maxLat.to_i == 0 && maxLng.to_i == 0)
				agg = Area.create(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng, elevation: 0, geonames_core: geoname)
				agg.save
			end
		end
		puts "\rProcessing aggregation 100%"
	end

	task :adjust_area => :environment do
		areas = Area.where("geonames_core_id IS NULL")
		puts areas.size.to_s + " area to adjust\n\n"

		areas.each do |a|
			geoname = nil
			i = 1
			puts "Passe for id " + a.id.to_s
			while geoname.nil?
				print "\rPassed " + i.to_s + " time"
				a.minLat -= step / 2
				a.minLng -= step / 2
				a.maxLng += step / 2
				a.maxLng += step / 2
				geoname = GeonamesCore.where("(latitude BETWEEN ? AND ?) AND (longitude BETWEEN ? AND ?) AND feature_class = ?", a.minLat, a.maxLat, a.minLng, a.maxLng, "P").order("population DESC").limit(1).first
				if !geoname.nil?
					puts "\nArea name find : " + geoname.name
				end
				a.geonames_core = geoname
				a.save
				i += 1
			end
			puts "Finish passed"
		end
		puts 'Finish adjusting area'
	end

	task :merge_area => :environment do 
		area_ids = Area.all.map(&:id)
		area_ids.each do |area_id|
			a = Area.find_by_id area_id
			other = Area.where("geonames_core_id = ? AND id != ?", a.geonames_core.id, a.id)
			if other.size != 0
				other.each do |o|
					puts "Work on area " + a.geonames_core.name + " / " + o.geonames_core.name
					if (a.minLat > o.minLat)
						a.minLat = o.minLat
					end
					if (a.minLng > o.minLng)
						a.minLng = o.minLng
					end
					if (a.maxLat < o.maxLat)
						a.maxLat = o.maxLat
					end
					if (a.maxLng < o.maxLng)
						a.maxLng = o.maxLng
					end
					area_ids.delete o.id
					a.save
					o.delete
				end
			end
		end
	end

	task :launch => :environment do |t,args|
	    ["area_detection:calculate", "area_detection:aggregate", "area_detection:adjust_area", "area_detection:merge_area"].each do |t|
	      Rake::Task[t].execute
	    end
  	end
end