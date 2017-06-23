module ExploreHelper


  SCALES = [0.3515625,0.3515625,0.3515625,0.17578125,0.087890625,0.0439453125,0.02197265625,0.010986328125,0.0054931640625,0.00274658203125,0.001373291015625,0.0006866455078125,0.00000005,0.00000005,0.00000005,0.00000005]
  #JS command to run on explore to generate that list : ratio = []; for (var i=0;i<15; i++) { map.setZoom(i); ratio[i] = (-map.getBounds().getSouthWest().lng()+map.getBounds().getNorthEast().lng())/$("#map_canvas").width(); }; console.log(JSON.stringify(ratio))
  #actually the formula is : SCALES[i] = 360 / (256 * 2^i)
  #except for the 3 last which have been divided by 10

  #CLUSTERING
  GROUP_DST = 50        #pixels
  COUNTRY_MAX_DST = 100  #pixels

  #SLICING
  ELEMENTS_PER_SLICE = 10  #number of elements to keep per slice


  #Asset files
  ASSET_TMP_DIR = "tmp/explore_assets_tmp"
  ASSET_FIN_DIR = "public/assets/explore"
  ASSET_OLD_DIR = "tmp/explore_assets_old"

  #BATCH SELECT SIZE
  BATCH_SIZE = 500

  def self.generate_assets
    begin
      start_time = Time.now

      FileUtils.mkdir_p(ASSET_TMP_DIR)
      @tmp_dir = Dir.mktmpdir "assets-", ASSET_TMP_DIR
      FileUtils.mkdir_p(@tmp_dir)
      FileUtils.chmod 0755, @tmp_dir

      Rails.logger.info "Generating assets within temporary directory #{@tmp_dir}"

      #Changing the transaction isolation level for improved perf and better mornings
      # -> may not be needed with find_in_batches
      ActiveRecord::Base.connection.reset!
      ActiveRecord::Base.connection.execute "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;"

      #Generating everything
      Clusterer.generate_assets @tmp_dir
      Slicer.generate_assets @tmp_dir

      #resetting the connection to reset transaction isolation
      # -> may not be needed with find_in_batches
      ActiveRecord::Base.connection.reset!

      #gzip all generated jsons for nginx
      `find #{@tmp_dir} -name '*.json' -exec sh -c "gzip -c9 '{}' > '{}.gz'" ';' -exec touch '{}' '{}.gz' ';'`

      # Replace the existing directory
      Rails.logger.info "Moving #{@tmp_dir} into #{ASSET_FIN_DIR}"
      FileUtils.mkdir_p(ASSET_FIN_DIR)
      FileUtils.rmtree(ASSET_OLD_DIR) if Dir.exists?(ASSET_OLD_DIR)
      FileUtils.chmod 0755, @tmp_dir
      FileUtils.mv(ASSET_FIN_DIR, ASSET_OLD_DIR)
      FileUtils.mv(@tmp_dir, ASSET_FIN_DIR)
      FileUtils.chmod 0755, ASSET_FIN_DIR
      Rails.logger.info "Purging old directories"
      FileUtils.rmtree(ASSET_OLD_DIR)
      FileUtils.rmtree(@tmp_dir)
      Rails.logger.info "Done generating assets with batch_size #{BATCH_SIZE} in #{Time.now-start_time} seconds"
    rescue
      Rails.logger.error "Error while generating assets : #{$!.message}"
      Rails.logger.debug $!.backtrace.join "\n"
      raise
    #ensure
    ###This line segfaults... since it's only some cleaning, let's ignore it...
    #  FileUtils.rmtree(@tmp_dir) if !@tmp_dir.blank? && Dir.exists?(@tmp_dir)
    end
  end


  module Clusterer

    def self.generate_assets dir
      clusters = generate_clusters
      @tmp_dir = dir

      # Writing the assets in a temporary directory
      Rails.logger.info "Writing files into #{@tmp_dir}"
      FileUtils.mkdir_p(@tmp_dir)
      SCALES.each_with_index do |scale, zoom_level|
        asset_name = "clusters_#{zoom_level}.json"
        File.open("#{@tmp_dir}/#{asset_name}", 'w') do |file|
          file.write clusters[zoom_level].to_json
        end
      end
    end

    class Cluster
      attr_accessor :lat, :lng, :count, :spots, :id

      class ProxySpot
        attr_accessor :id
        def self.new(args=nil)
          cluster = super()
          cluster.id = args[:id] rescue nil
          cluster
        end
      end

      def self.new(args=nil)
        cluster = super()
        cluster.init(args)
      end

      def init(args)
        @@next_id = @@next_id + 1 rescue 1
        self.id = @@next_id
        self.count = 0
        self.spots = []
        return self unless args.is_a? Hash
        self.lat = args[:lat]
        self.lng = args[:lng]
        self.count = args[:count]
        self.spots = args[:spots]
        self
      end

      def to_s
        "<Cluster #{self.count} (#{self.lat},#{self.lng})>"
      end

      def as_json(*args)
        {:id => self.id, :count => self.count, :spot_ids => self.spots.map(&:id),  :lat => self.lat, :lng => self.lng}.as_json(*args)
      end

      def from_json(arg)
        self.id = arg['id']
        @@next_id = self.id if (self.id > @@next_id rescue true)
        self.lat = arg['lat']
        self.lng = arg['lng']
        self.count = arg['count']
        self.spots = arg['spot_ids'].map do |id| ProxySpot.new(:id => id) rescue nil end
        self
      end
    end


    def self.generate_clusters

      cluster_seeds = []
      clusters = []
      SCALES.each_with_index do |scale, zoom|
        cluster_seeds[zoom] = []
        clusters[zoom] = []
      end

      Spot.where('lat is not null and `long` is not null and (lat <> 0.0 or `long` <> 0.0)').group_by(&:country_id).each do |country_id, spot_list|

        #get some info about the country
        country = Country.find(country_id)
        geonames_coord = ActiveRecord::Base.connection.select_one("SELECT latitude, longitude from geonames_countries, geonames_cores where ISO = '#{country.ccode.upcase}' AND geonames_countries.geonames_id = geonames_cores.id")
        Rails.logger.debug "country not found in geonames #{country.ccode} (#{country.id})" if geonames_coord.nil?

        #calculates the span covering these spots
        country_span = get_span(spot_list)

        #For each scale decide whether to use only one marker for the country, or to use the scattered spots
        SCALES.each_with_index do |scale, zoom|
          if country_span[:lat].max - country_span[:lat].min < COUNTRY_MAX_DST * scale then
            #let's use the country
            if geonames_coord.nil? then
              #If not found in geocores then we use the middle of the span
              cluster_seeds[zoom].push Cluster.new({:lat => (country_span[:lat].max+country_span[:lat].min)/2, :lng =>(country_span[:lng].max+country_span[:lng].min)/2, :count => spot_list.count, :spots => spot_list})
            else
              #if geonames can say where the center of the country is, then let's place the cluster over there
              cluster_seeds[zoom].push Cluster.new({:lat => geonames_coord['latitude'], :lng =>geonames_coord['longitude'], :count => spot_list.count, :spots => spot_list})
            end
          else
            #let's use the single spots
            cluster_seeds[zoom] += spot_list.map do |spot| Cluster.new({:lat => spot.lat, :lng => spot.lng, :count => 1, :spots => [spot]}) end
          end
        end

      end

      #Group into clusters of each zoom level
      SCALES.each_with_index do |scale, zoom|
        Rails.logger.info "Clustering zoom level #{zoom}"
        clusters[zoom] = group_into_clusters(cluster_seeds[zoom], scale)
        Rails.logger.info "Clustering zoom level #{zoom} done : #{clusters[zoom].count} clusters"
        Rails.logger.debug "Cluster density : #{clusters[zoom].count * scale**2 }"
      end

      return clusters
    end

    def self.group_into_clusters(cluster_seeds, scale, clusters=[])
      Rails.logger.debug "Layer has #{cluster_seeds.count} seeds"
      cluster_seeds.each_with_index do |seed, seed_idx|
        assigned = false
        clusters.each do |target|
          #if the seed is close to a target
          if (seed.lat - target.lat)**2 + (seed.lng-target.lng)**2 < (GROUP_DST*scale)**2 then
            target.spots += seed.spots
            target.count += seed.count
            assigned = true
            #TO TEST : barycentre des deux clusters ?
            break
          end
        end
        clusters.push seed if !assigned
        Rails.logger.debug "#{seed_idx} seeds parsed into #{clusters.count} clusters" if seed_idx%1000 == 0
      end

      return clusters
    end

    def self.get_span(spot_list)
      return nil if spot_list.count == 0
      min_lat = spot_list.first.lat
      max_lat = spot_list.first.lat
      min_lng = spot_list.first.lng
      max_lng = spot_list.first.lng

      spot_list.each do |spot|
        max_lat = spot.lat if spot.lat > max_lat
        min_lat = spot.lat if spot.lat < min_lat

        lng = best_modulo_to_span(spot.lng, min_lng, max_lng)
        max_lng = lng if lng > max_lng
        min_lng = lng if lng < min_lng
      end
      return {:lat => min_lat..max_lat, :lng => min_lng..max_lng}
    end

    def self.dst_to_span(lng, min_lng, max_lng)
      if lng < min_lng then
        return min_lng - lng
      elsif lng > max_lng then
        return lng - max_lng
      else
        return 0
      end
    end

    #Find the best longitude to use
    def self.best_modulo_to_span(lng, min_lng, max_lng)
      dst = dst_to_span(lng, min_lng, max_lng)
      return lng if dst == 0
      dst_minus = dst_to_span(lng-360, min_lng, max_lng)
      dst_plus = dst_to_span(lng+360, min_lng, max_lng)

      return lng-360 if dst_minus < dst && dst_minus < dst_plus
      return lng+360 if dst_plus < dst && dst_plus < dst_minus
      return lng
    end

    def self.del_spot spot
      spot_id = spot.id
      SCALES.each_with_index do |scale, zoom_level|
        begin
          asset_name = "clusters_#{zoom_level}.json"
          data = JSON.parse(File.read "#{ASSET_FIN_DIR}/#{asset_name}" )
          data = [data] if data.is_a? Hash
          data.each do |c|
            if c['spot_ids'].include? spot_id then
              c['spot_ids'].reject! do |id| id == spot_id end
              c['count'] -= 1
            end
          end
          File.open("#{ASSET_FIN_DIR}/#{asset_name}", 'w') do |file|
            file.write data.to_json
          end
          ExploreHelper.gzip_asset_file "#{ASSET_FIN_DIR}/#{asset_name}"
        rescue
          Rails.logger.warn "Error updating explore clusters #{asset_name} : #{$!.message}"
          Rails.logger.debug $!.backtrace.join("\n")
        end
      end
    end

    def self.add_spot spot
      spot_id = spot.id
      SCALES.each_with_index do |scale, zoom_level|
        begin
          asset_name = "clusters_#{zoom_level}.json"
          data = JSON.parse(File.read "#{ASSET_FIN_DIR}/#{asset_name}" )
          data = [data] if data.is_a? Hash
          data.each do |c|
            if c['spot_ids'].include? spot_id then
              c['spot_ids'].reject! do |id| id == spot_id end
              c['count'] -= 1
            end
          end
          clusters = data.map do |c| Cluster.new.from_json(c) end
          clusters = group_into_clusters [ Cluster.new({:lat => spot.lat, :lng => spot.lng, :count => 1, :spots => [spot]}) ], zoom_level, clusters
          File.open("#{ASSET_FIN_DIR}/#{asset_name}", 'w') do |file|
            file.write clusters.to_json
          end
          ExploreHelper.gzip_asset_file "#{ASSET_FIN_DIR}/#{asset_name}"
        rescue
          Rails.logger.warn "Error updating explore clusters : #{$!.message}"
          Rails.logger.debug $!.backtrace.join("\n")
        end
      end
    end

  end




  module Slicer

    def self.generate_assets dir
      t = Time.now

      #make sure temporary tables are not there
      ['spots', 'dives', 'shops', 'ads', 'countries'].each do |table|
        ActiveRecord::Base.connection.execute  "drop temporary table explore_#{table}" rescue nil
      end

      #these are equivalents to slice_index
      cols = []
      SCALES.each_with_index do |scale, zoom_level|
        a = "least(greatest( sin(lat*PI()/180), 1/1000000-1), 1-1/1000000)"
        cols.push "CONCAT(
          FLOOR(POW(2,#{zoom_level}) * ((180+`long`) % 360) / 360),
          '_',
          FLOOR(POW(2,#{zoom_level}) * (128 - 0.5 * LOG( (1+#{a}) / (1-#{a}) ) * 40.74366543152521) / 256)
        ) L#{zoom_level}"
      end

      cols_lng = []
      SCALES.each_with_index do |scale, zoom_level|
        a = "least(greatest( sin(lat*PI()/180), 1/1000000-1), 1-1/1000000)"
        cols_lng.push "CONCAT(
          FLOOR(POW(2,#{zoom_level}) * ((180+`lng`) % 360) / 360),
          '_',
          FLOOR(POW(2,#{zoom_level}) * (128 - 0.5 * LOG( (1+#{a}) / (1-#{a}) ) * 40.74366543152521) / 256)
        ) L#{zoom_level}"
      end

      cols_shop_update = []
      SCALES.each_with_index do |scale, zoom_level|
        a = "least(greatest( sin(shops.lat*PI()/180), 1/1000000-1), 1-1/1000000)"
        cols_shop_update.push "L#{zoom_level} = CONCAT(
          FLOOR(POW(2,#{zoom_level}) * ((180+`shops`.`lng`) % 360) / 360),
          '_',
          FLOOR(POW(2,#{zoom_level}) * (128 - 0.5 * LOG( (1+#{a}) / (1-#{a}) ) * 40.74366543152521) / 256)
        )"
      end

      # Getting only the important data
      ActiveRecord::Base.connection.execute "create temporary table explore_spots as SELECT `spots`.id id, 0 score, #{cols.join ','} FROM `spots`"
      ActiveRecord::Base.connection.execute "create temporary table explore_dives as SELECT `dives`.id id, dives.score, #{cols.join ','} FROM dives, spots where dives.spot_id = spots.id and dives.privacy = 0"
      ActiveRecord::Base.connection.execute "create temporary table explore_shops as SELECT `shops`.id id, 0 score, #{cols_lng.join ','} FROM `shops` where lat is not null and lng is not null"
      ActiveRecord::Base.connection.execute "create temporary table explore_ads   as SELECT `advertisements`.id id, 0 score, #{cols_lng.join ','} FROM `advertisements` where ended_at is null"
      ActiveRecord::Base.connection.execute "create temporary table explore_countries as SELECT `countries`.id id, 0 score, #{cols.join ','} FROM countries, spots where countries.id = spots.country_id and NOT (spots.lat = 0 and spots.`long` = 0)"

      #ads may not have a lat/lng, in which case they are centered on the shop
      ActiveRecord::Base.connection.execute "update explore_ads, advertisements, users, shops set #{cols_shop_update.join ','} WHERE explore_ads.L0 is NULL and explore_ads.id = advertisements.id AND advertisements.user_id = users.id and users.shop_proxy_id = shops.id"

      # Creating indexes
      ['spots', 'dives', 'shops', 'ads', 'countries'].each do |table|
        SCALES.each_with_index do |scale, zoom_level|
          ActiveRecord::Base.connection.execute "CREATE INDEX idx_explore_#{table}_#{zoom_level} ON explore_#{table}(L#{zoom_level}, score)"
        end
      end

      Rails.logger.info "Item selection within mysql : #{Time.now-t} seconds"


      SCALES.each_with_index do |scale, zoom_level|
        FileUtils.mkdir_p("#{dir}/#{zoom_level}")
      end

      t = Time.now
      ExploreHelper.handle_slices dir
      Rails.logger.info "Slicing : #{Time.now-t} seconds"

    end


    def self.slice_index(lat, lng, zoom_level)
      x = (2**zoom_level * ((180+lng) % 360) / 360).floor

      #Formula taken on http://mathworld.wolfram.com/MercatorProjection.html
      #that's exactly what google map uses in map.getProjection().fromLatLngToPoint
      a = Math.sin(lat*Math::PI/180)
      a = [[a,-1+1e-6].max, 1-1e-6].min # Google uses 1e-15, but 1e-6 gives strict positive numbers
      y = (2**zoom_level * (128 - 0.5 * Math.log( (1+a) / (1-a) ) * 40.74366543152521) / 256).floor

      return "#{x}_#{y}"
    end


    def self.del_element type, lat, lng, element_id
      SCALES.each_with_index do |scale, zoom_level|
        idx = slice_index(lat, lng, zoom_level)
        filename = "#{ASSET_FIN_DIR}/#{zoom_level}/#{idx}.data.json"
        data = JSON.parse(File.read filename ) rescue next
        has_changed = false
        data[type].reject! do |el|
          r = el['id'] == element_id
          has_changed ||= r
          r
        end
        next if !has_changed
        File.open(filename, 'w') do |file|
          file.write data.to_json
        end
        ExploreHelper.gzip_asset_file filename
      end
    end

    def self.add_element type, element
      return if element.nil?
      element_id = element['id'] || element[:id]
      lat = element['lat'] || element[:lat]
      lng = element['lng'] || element[:lng]
      SCALES.each_with_index do |scale, zoom_level|
        idx = slice_index(lat, lng, zoom_level)
        filename = "#{ASSET_FIN_DIR}/#{zoom_level}/#{idx}.data.json"
        data = JSON.parse(File.read filename ) rescue next
        next if data[type].count >= ELEMENTS_PER_SLICE
        data[type].push element
        File.open(filename, 'w') do |file|
          file.write data.to_json
        end
        ExploreHelper.gzip_asset_file filename
      end
    end



  end

  def self.gzip_asset_file filename
    gz_filename = "#{filename}.gz"
    begin
      Zlib::GzipWriter.open(gz_filename, 9) do |gz|
        gz.mtime = File.mtime(filename)
        gz.orig_name = filename
        gz.write IO.binread(filename)
        gz.close
      end
      File.utime(File.atime(filename), File.mtime(filename), gz_filename) rescue nil
      File.unlink(gz_filename) if File.stat(filename).size < File.stat(gz_filename).size
    rescue
      Rails.logger.warn "Error while zipping assets file #{filename} : #{$!.message}"
      Rails.logger.debug $!.backtrace.join("\n")
    end
  end



  def self.handle_slices dir, zoom_level=0, slices = [[0,0]], caches = []

    #initializing stats variables
    @slice_nb ||= 0
    @start_time ||= Time.now
    unless @stats then
      @stats = { :time => {}, :count => {}, :generated => {} }
      ['spots', 'dives', 'shops', 'countries', 'ads', 'users'].each do |item|
        @stats[:count][item] = 0
        @stats[:generated][item] = 0
        @stats[:time][item] = 0
      end
    end

    slices.each do |slice|
      x = slice[0]
      y = slice[1]

      main_items = ['spots', 'dives', 'shops', 'countries', 'ads']
      out_items  = ['spots', 'dives', 'shops', 'countries', 'ads', 'users']

      new_cache = {}
      vals = {}
      out_items.each do |item|
        new_cache[item] = []
        vals[item] = []
      end

      # First of all, decide which objects we want in the asset file
      main_items.each do |item|
        vals[item] = ActiveRecord::Base.connection.select_values "SELECT id from explore_#{item} where L#{zoom_level} = '#{x}_#{y}' order by score DESC limit #{ELEMENTS_PER_SLICE}"
      end

      # We need to include dive_ids of the spots
      if vals['spots'].count > 0 then
        vals['dives'] += Media.select_values_sanitized "Select dives.id from dives where spot_id in (:ids) and privacy = 0 limit 1000", :ids => vals['spots']
        vals['dives'].uniq!
      end

      # For dives we need to include spot_ids and user_ids
      if vals['dives'].count > 0 then
        v = Media.select_all_sanitized "Select spot_id, user_id from dives where id in (:ids)", :ids => vals['dives']
        vals['users'] += v.map do |r| r['user_id'] end
        vals['spots'] += v.map do |r| r['spot_id'] end
        vals['spots'].uniq!
        vals['users'].uniq!
      end

      # For spots, we need to include country_ids
      if vals['spots'].count > 0 then
        vals['countries'] += Media.select_values_sanitized "Select distinct country_id from spots where id in (:ids)", :ids => vals['spots']
        vals['countries'].uniq!
        vals['shops'] += Media.select_values_sanitized "Select distinct shop_id from dives where spot_id in (:ids) AND shop_id IS NOT NULL", :ids => vals['spots']
        vals['shops'].uniq!
      end

      # If we don't want to put anything in this asset file,
      # then there is no need to write it, or to recurse on the sub-tiles
      item_count = vals.values.map(&:count).sum
      next if item_count == 0

      #Initiate asset file
      filename = "#{dir}/#{zoom_level}/#{x}_#{y}.data.json"
      asset_file = File.open(filename, "w")
      asset_file.write "{"

      #now that we know what we want in the slice, we need to generate the content
      out_items.each_with_index do |item, idx|

        #if there is nothing to do, just skip the loops below
        if vals[item].count == 0
          asset_file.write "," if idx > 0
          asset_file.write "\"#{item}\":[]"
          next
        end

        start_time = Time.now
        needed_vals = []
        slice_vals = []

        @stats[:count][item]+=vals[item].count

        # Get json from cached data
        vals[item].each do |id|
          json = nil
          caches.each do |cache|
            json = cache[item][id]
            slice_vals.push json unless json.nil?
            break unless json.nil?
          end
          needed_vals.push id if json.nil?
        end

        # For items not found then fetch them through model
        if needed_vals.count > 0 then
          @stats[:generated][item] += needed_vals.count

          relation = nil
          case item
          when "shops" then
            relation = Shop.includes([:reviews, :dives => [:spot], :user_proxy => [:dives]]).where('shops.id' => needed_vals)
          when "dives" then
            relation = Dive.where(:privacy => 0).includes([:trip, :picture_album_pictures => [:picture => [:user, :cloud_thumb, :cloud_large, :cloud_small, :cloud_medium]], :shop => [:user_proxy],
              :user => [:public_spots, :dives => [:trip, :user, :shop => [:user_proxy], :picture_album_pictures => [:picture], :spot => [:users]], :public_dives => [:trip, :user, :spot, :shop => [:user_proxy], :picture_album_pictures => [:picture] ]],
              :spot => [:country, :location, :region,
                :users,
                :dives => [:trip, :shop, :spot, :picture_album_pictures => [:picture => [:user, :cloud_thumb, :cloud_large, :cloud_small, :cloud_medium]],
                  :user => [:public_dives, :public_spots] ]]
              ]).where('dives.id' => needed_vals)
          when "spots" then
            relation = Spot.includes([:country, :location, :region, :users,
                :dives => [:trip, :spot, :shop => [:user_proxy], :picture_album_pictures => [:picture => [:user, :cloud_thumb, :cloud_large, :cloud_small, :cloud_medium]],
                  :user => [:public_dives, :public_spots]
              ]]).where('spots.id' => needed_vals)
          when "countries" then
            relation = Country.where('countries.id' => needed_vals)
          when "ads" then
            relation = Advertisement.where('advertisements.id' => needed_vals)
          when "users" then
            relation = User.where('users.id' => needed_vals)
          else raise DBTechnicalError.new "missing relation", item: item
          end

          relation.each do |stuff|
            json = stuff.to_api(:search_light).to_json
            new_cache[item][stuff.id] = json unless json.nil?
            slice_vals.push json unless json.nil?
          end
        end

        #Write the slice data to the file
        asset_file.write "," if idx > 0
        asset_file.write "\"#{item}\":["
        asset_file.write slice_vals.join(',')
        asset_file.write ']'
        @stats[:time][item] += Time.now - start_time
      end

      asset_file.write '}'
      asset_file.close


      @slice_nb += 1
      if @slice_nb % 1000 == 0 then
        Rails.logger.info "Slices done : #{@slice_nb} #{Time.now-@start_time}"
        Rails.logger.info @stats.pretty_inspect
      end

      if zoom_level < SCALES.length-1 then
        next_cache = [] + caches + [new_cache]
        self.handle_slices dir, zoom_level+1, [ [2*x, 2*y], [2*x, 2*y+1], [2*x+1, 2*y], [2*x+1, 2*y+1] ], next_cache
      end
    end
  end



  def self.stats_explore_js
    target = 7
    freq = {}
    cnt = 0
    ActiveRecord::Base.connection.select_values("select url from stats_logs where url like '/assets/explore/%'").each do |line|
      data = line.scan(/explore.([0-9]*).([0-9]*)_([0-9]*)/)[0] rescue nil
      next if data.nil?
      cnt += 1
      zoom = data[0].to_i
      x = data[1].to_i
      y = data[2].to_i
      if zoom == target
        xt = x
        yt = y
      elsif zoom > target
        dz = zoom-target
        xt = (x / 2**dz).to_i
        yt = (y / 2**dz).to_i
        freq["#{xt}_#{yt}"] ||= 0
        freq["#{xt}_#{yt}"] += 1
      elsif zoom < target
        dz = target-zoom
        xt = (x * 2**dz).to_i
        yt = (y * 2**dz).to_i
        df = 1.0 / 2**(2*dz)
        (2**dz).times do |dx|
          (2**dz).times do |dy|
            freq["#{xt}_#{yt}"] ||= 0
            freq["#{xt}_#{yt}"] += df
          end
        end
      end
    end

    sorted_values = freq.values.sort
    nb_values = sorted_values.count

    out = ""
    freq.each do |idx, cnt|
      data = idx.scan(/([0-9]*)_([0-9]*)/)[0]
      x = data[0].to_f
      y = data[1].to_f

      lng = 360*x/2**target - 180
      lng2 = 360*(x+1)/2**target - 180

      lm = Math.exp ( 2 * (128 - 256 * y / (2**target)) / 40.74366543152521 )
      lat = Math.asin( (lm-1)/(lm+1) ) * 180 / Math::PI

      lm2 = Math.exp ( 2 * (128 - 256 * (y+1) / (2**target)) / 40.74366543152521 )
      lat2 = Math.asin( (lm2-1)/(lm2+1) ) * 180 / Math::PI


      c1 = [0, 238, 0]
      c2 = [213, 182, 30]
      c3 = [255, 0, 0]
      opacity = 0.5
      stop0 = sorted_values[0.86*nb_values]
      stop1 = sorted_values[0.94*nb_values]
      stop2 = sorted_values[0.998*nb_values]

      if cnt < stop0 then
        next
      elsif cnt < stop1 then
        a = (cnt-stop0)/stop1
        c = [c1[0]*(1-a) + c2[0]*a,
          c1[1]*(1-a) + c2[1]*a,
          c1[2]*(1-a) + c2[2]*a]
      elsif cnt < stop2 then
        a = (cnt-stop1)/stop2
        c = [c2[0]*(1-a) + c3[0]*a,
          c2[1]*(1-a) + c3[1]*a,
          c2[2]*(1-a) + c3[2]*a]
      else
        c = c3
      end

      color = sprintf "#%02x%02x%02x", c[0], c[1], c[2]

      out += "new google.maps.Rectangle({
            strokeWeight: 0,
            fillColor: '#{color}',
            fillOpacity: #{opacity},
            map: map,
            bounds: new google.maps.LatLngBounds(
              new google.maps.LatLng(#{lat2}, #{lng}),
              new google.maps.LatLng(#{lat}, #{lng2}))
          });
          "
    end

    return out
  end


end
