namespace :region do

	task :bound => :environment do
		region = Region.all

		region.each do |r|
=begin
			if r.nesw_bounds != nil
				puts "#{r.id}"
				r.nesw_bounds = JSON.unparse(YAML.load(r.nesw_bounds))
				r.save!
			end
=end
			if r.update_bounds != false
				puts "#{r.id} : sucessfully updated"
			else
				puts "#{r.id} : failed to update"
			end

		end
		puts "\n bounds updated"
	end

	task :list_spots => :environment do
		region = Region.where("nesw_bounds is not null")
		region.each do |r|
			nesw_bounds= r.nesw_bounds
		    minLat = r.nesw_bounds["southwest"]["lat"]
		    minLng = r.nesw_bounds["southwest"]["lng"]
		    maxLat = r.nesw_bounds["northeast"]["lat"]
		    maxLng = r.nesw_bounds["northeast"]["lng"]
			if minLng > maxLng
				spots=Spot.where("(spots.lat between ? and ?) and not (spots.long between ? and ? )",minLat,maxLat,minLng,maxLng)
			else
				spots=Spot.where("(spots.lat between ? and ?) and (spots.long between ? and ? )",minLat,maxLat,minLng,maxLng)
			end
			spots.each do |s|
				if s.region_id==nil
					s.region_id=r.id
					s.save!
					puts "#{s.id} updated"
				end
			end
		end
	end
	
end
