require 'jammit'
require 'sqlite3'


namespace :assets do

  desc "Generationg and packaging all assets"
  task :all => :environment do |t,args|
    ["assets:explore", "assets:mobilespots", "assets:mobilespotsdb", "assets:jammit", "assets:precompile"].each do |t|
      Rake::Task[t].execute
    end
  end

  desc "cleaning all assets"
  task :clean => :environment do |t,args|
  end

  desc "Packaging assets with Jammit"
  task :jammit => :environment do |t, args|
    Jammit.package!({:base_url => ROOT_URL, force: true})
  end

  desc "Generating the data JS for explore"
  task :old_explore => :environment do |t, args|
    url =  "#{ROOT_URL}api/explore/all"
    ::Rails.logger.info "Calling #{url} to generate explore_data.js"
    status, header, response = Rails.application.call(Rack::MockRequest.env_for(url))
    raise DBTechnicalError.new "Error while generating axplore_data.js" if status != 200
    `mkdir -p public/assets`
    File.open("public/assets/explore_data.js", "w") {|f| f.write response.body }
    `cat public/assets/explore_data.js | gzip -9 > public/assets/explore_data.js.gz`
    `touch public/assets/explore_data.js public/assets/explore_data.js.gz`
  end


  desc "Generating the clusters for explore"
  task :explore => :environment do |t, args|
    ExploreHelper.generate_assets
  end


  desc "Updating exchange rates"
  task :rates => :environment do |t,args|
    eu_bank = EuCentralBank.new
    eu_bank.update_rates('config/default_exchange_rates.xml')
    eu_bank.update_rates
    eu_bank.save_rates('tmp/exchange_rates.xml')
  end


  desc "Generating the fish occurence JS data for the species picker"
  task :species => :environment do |t, args|
    radius = 5
    sh "mkdir -p public/assets/species"
    (-90..90).each do |lat|
      if (lat%radius) != 0 then next end
      (-180..180).each do |lng|
        if (lng%radius) != 0 then next end
        filename = "public/assets/species/species_data_#{lat}_#{lng}_#{radius}.js"
        puts "processing #{filename}\n"
        if lat+radius > 90
          lat_clause = "lat >= #{(lat-radius)}"
        elsif lat-radius < -90
          lat_clause = "lat <= #{(lat+radius)}"
        else
          lat_clause = "lat <= #{(lat+radius)} AND lat >= #{(lat-radius)}"
        end
        if lng+radius > 180
          lng_clause ="lng >= #{(lng-radius)} OR lng <= #{(lng+radius-360)}"
        elsif lng-radius < -180
          lng_clause ="lng >= #{(lng-radius+360)} OR lng <= #{(lng+radius)}"
        else
          lng_clause ="lng >= #{(lng-radius)} AND lng <= #{(lng+radius)}"
        end

        fish_list = FishFrequency.all(:conditions => "(#{lat_clause}) AND (#{lng_clause}) AND eolsnames.taxonrank = 'species'", :group => "gbif_id", :order => "count(*) desc", :joins => :eolsnames, :include => :eolsnames)
        species = {}
        fish_list.each do |o|
          begin
            s = o.eolsnames.first
            if species[s.category].nil? then species[s.category] = [] end
            p = s.parent
            species[s.category] << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank  }
          rescue
          end
        end
        File.open(filename, "w") {|f| f.write "species_data=#{species.to_json.html_safe};" }
        sh "cat #{filename} | gzip -9 > #{filename}.gz"
      end
    end
    ##finally build a list of all species
    species = {}
    filename = "public/assets/species/species_data_all.js"
    puts "processing #{filename}\n"
    Eolsname.find_each(:conditions => "taxonrank='species' AND category IS NOT NULL AND category NOT LIKE 'other' AND category NOT LIKE  'undefined'" ) do |s|
      begin
        if species[s.category].nil? then species[s.category] = [] end
        species[s.category] << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank  }
      rescue
        puts "#{s.id} failed: "+$!.message
      end
    end
    File.open(filename, "w") {|f| f.write "species_data_all=#{species.to_json.html_safe};" }
    sh "cat #{filename} | gzip -9 > #{filename}.gz"


  end


  desc "Generating the spot files for mobile search"
  task :mobilespots => :environment do |t, args|
    sh "mkdir -p public/assets"
    filename="public/assets/mobilespots.js"
    coco = [] ## best variable name ever :)
    spotlist = Spot.all.reject!{|s| (s.flag_moderate_private_to_public == false && s.private_user_id.nil?)||s.id == 1}
    spotlist.each {|s| coco << s.to_api(:mobile)}

    File.open(filename, "w") {|f| f.write "spot_data=#{coco.to_json.html_safe};" }
    sh "cat #{filename} | gzip -9 > #{filename}.gz"
  end

  desc "Generating the spot database files for mobile search"
  task :mobilespotsdb => :environment do |t, args|
    sh "mkdir -p public/assets"
    tmpfile="tmp/mobilespots.db"
    filename="public/assets/mobilespots.db"
    File.delete(tmpfile) if File.exist?(tmpfile)
    db = SQLite3::Database.new tmpfile
    db.execute "CREATE TABLE spots(id int, name varchar(255), location_name varchar(255), country_name varchar(255), lat float, lng float, country_id int, region_id int, location_id int, private_user_id int)"
    spotlist = Spot.all.reject!{|s|
      (!s.moderate_id.nil?)||(!s.redirect_id.nil?)||(s.flag_moderate_private_to_public == false && s.private_user_id.nil?)||(s.id == 1)
    }
    db.transaction
    spotlist.each do |s| db.execute "insert into spots (id, name, location_name, country_name, lat, lng, country_id, region_id, location_id, private_user_id) VALUES (?,?,?,?,?,?,?,?,?,?)", [s.id, s.name, s.location_name, s.country_name, s.lat, s.lng, s.country.id, s.region_id, s.location_id, s.private_user_id] end
    db.commit
    db.execute "CREATE UNIQUE INDEX spots_id on spots(id)"
    db.execute "CREATE INDEX spots_coords on spots(lat, lng)"
    db.execute "CREATE VIRTUAL TABLE spots_fts USING fts3(name TEXT)"
    db.execute "INSERT INTO spots_fts(docid, name) SELECT id, name from spots"
    db.execute "CREATE TABLE locations (id int, name varchar(255))"
    db.execute "CREATE TABLE regions (id int, name varchar(255))"
    db.execute "CREATE TABLE countries (id int, code CHAR(6), name varchar(255))"
    Media.select_all_sanitized("SELECT id, name from locations").each do |l| db.execute "INSERT INTO locations (id, name) VALUES (?,?)", [l['id'], l['name']] end
    Media.select_all_sanitized("SELECT id, name from regions").each do |l| db.execute "INSERT INTO regions (id, name) VALUES (?,?)", [l['id'], l['name']] end
    Media.select_all_sanitized("SELECT id, ccode, cname name from countries").each do |l| db.execute "INSERT INTO countries (id, code, name) VALUES (?,?,?)", [l['id'], l['ccode'], l['name']] end
    db.execute "CREATE UNIQUE INDEX locations_id on locations(id)"
    db.execute "CREATE UNIQUE INDEX regions_id on regions(id)"
    db.execute "CREATE UNIQUE INDEX countries_id on countries(id)"
    db.close
    File.rename(tmpfile, filename)
    sh "cat '#{filename}' | gzip -9 > #{filename}.gz"
  end

end

namespace :cleanup do


####
##  Cleanup function for SPOTS (and locations/regions)
####
  desc "Launch spot database maintenance tasks"
  task :maintain_spots => :environment do |t,args|
    ["cleanup:moderate_id_check", "cleanup:spots", "cleanup:moderate_non_checked_spots", "cleanup:fix_spot_owners", "cleanup:locations", "cleanup:regions", "cleanup:fix_spot_zoom"].each do |t|
      Rake::Task[t].execute
    end
  end

  desc "Removes locations with no spots attached"
  task :locations => :environment do |t, args|
    locs_destroyed = []
    Location.all.each do |l|
      if l.spots.count == 0 && l.wiki.nil? && l.nesw_bounds.blank?
        locs_destroyed.push l.id
        l.destroy
      end
    end
    puts "#{locs_destroyed.count} unused locations cleaned up: #{locs_destroyed.to_s}"
  end

  desc "Removes locations with no spots attached and no wiki entry"
  task :regions => :environment do |t, args|
    regs_destroyed = []
    Region.all.each do |r|
      if r.spots.count == 0 && r.wiki.nil? && r.nesw_bounds.blank?
        regs_destroyed.push r.id
        r.destroy
      end
    end
    puts "#{regs_destroyed.count} unused regions cleaned up: #{regs_destroyed.to_s}"
  end

  desc "Ensure no moderate_id points to a spot that doesn't exist and fix flags"
  task :moderate_id_check => :environment do |t, args|
    spots_fixed = []
    Spot.where("moderate_id is not null").each do |s|
      ##ensure ancestor exists
      begin
        Spot.find(s.moderate_id)
      rescue
        s.moderate_id = nil
        s.save!
      end
      if s.flag_moderate_private_to_public.nil?
        s.flag_moderate_private_to_public = true
        s.save
      end
    end
    puts "moderate_id_check : #{spots_fixed.count} spots moderate_id fixed : #{spots_fixed.to_s}"
  end

  desc "Removes private spots with no dives"
  task :spots => :environment do |t, args|
    spots_destroyed = []
    Spot.where("flag_moderate_private_to_public is not null").each do |s|
      if s.dives.count == 0
        s.reload ## avoid inconsistencies
        spots_destroyed.push s.id
        ##Rails.logger.debug "killing spot #{s.id} #{s.to_api(:moderation).to_s}"
        s.remove_from_moderation_chain
        s.destroy
      end
    end
    puts "unused private spots : #{spots_destroyed.count} spots cleaned up : #{spots_destroyed.to_s}"
  end

  desc "Removes non checked spots from public"
  task :moderate_non_checked_spots => :environment do |t, args|
    Spot.where("verified_user_id is NULL and flag_moderate_private_to_public is NULL").each do |s|
      s.flag_moderate_private_to_public = true
      s.save
    end
  end

  desc "Fixes private spots with many users"
  task :fix_spot_owners => :environment do |t, args|
    spots_fixed = []
    Spot.where("flag_moderate_private_to_public is not null and id > 1").each do |s|
      s.fix_owners
    end
    puts "private spots with mre than one user : #{spots_fixed.count} spots fixed : #{spots_fixed.to_s}"
  end
  desc "Fixes zoom value of spots between 6 and 12"
  task :fix_spot_zoom => :environment do |t, args|
    countspots = Spot.where("zoom < 6 OR zoom > 12").count
    Spot.where("zoom < 6 OR zoom > 12").each do |s|

      if s.zoom < 6 then s.zoom = 6 end
      if s.zoom > 12 then s.zoom = 12 end
      s.save!
      ##delete the map since it has to be remade
      begin
        File.delete("#{ROOT_URL}map_images/map_#{s.id}.jpg")
      rescue

      end
    end
    puts "Fixed zoom in #{countspots} spots"
  end
end
