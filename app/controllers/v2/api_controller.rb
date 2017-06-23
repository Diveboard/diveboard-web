class V2::ApiController < ::ApiController

  def search_area
    if params[:q].nil?
      render :json => {:success => false}
    end
    search = GeonamesAlternateName.search(Riddle::Query.escape(params[:q])).uniq{|x| x.geonames_core}.first(10)
    location = GeonamesCore.search Riddle::Query.escape(params[:q]), :with => {:ppl => true},:order_by=>'population desc' ,:group_by => :country_code, :limit=>5
    if location.empty?
      location = Array.new
      distances = Array.new
      points = GeonamesCore.search Riddle::Query.escape(params[:q])
      points[0..3].each do |p|
        ppl = p.findPPL
        location.push ppl
      end
    end
    if location.empty?
      location= Array.new
      
      points = Array.new
      search_text = params[:q].split(' ').reject{|w| w.length < 4 }.join(' ') 
      points = GeonamesCore.search search_text.gsub(" "," | ") ,:match_mode => :boolean
      points[0..3].each do |p|
        ppl = p.findPPL
        location.push ppl
      end
    end
    location.uniq!
    results = []
    location.each do |l|
      begin 
        results << {:search => l.country.name, :name => l.name,:link => l.destinationLink, :type => "location"}
      rescue
        #we skip
      end
    end
    search.each do |s|
      begin
        if !s.geonames_core.area.nil?
          a = s.geonames_core.area
          results << {:search => s.name, :name => a.geonames_core.name, :link => a.fullpermalink, :type => "exact"}
        elsif !Area.where("(? BETWEEN minlat AND maxlat) AND (? BETWEEN minlng AND maxlng) AND active = true", s.geonames_core.latitude, s.geonames_core.longitude).first.nil?
          a = Area.where("(? BETWEEN minlat AND maxlat) AND (? BETWEEN minlng AND maxlng) AND active = true", s.geonames_core.latitude, s.geonames_core.longitude).first
          results << {:search => s.name, :name => a.geonames_core.name, :link => a.fullpermalink, :type => "in"}
        else
          a = Area.near_areas(s.geonames_core.latitude, s.geonames_core.longitude, 1).first
          results << {:search => s.name, :name => a.geonames_core.name, :link => a.fullpermalink, :type => "near"}
        end
      rescue
        #we skip
      end
    end
    results.sort! { |a,b| a[:type].downcase <=> b[:type].downcase }
    render :json => {:success => true, :areas => results}
  end

  def shop_details_edit
    if params[:shop_id].nil?
      render :json => {:success => false}
    end
    shop = Shop.find(params[:shop_id])
    if params.has_key?(:language)
      ShopDetail.where(shop_id: params[:shop_id], kind: "lang").delete_all
      if !params[:language].nil?
        params[:language].each do |l|
          ShopDetail.create(kind: "lang", value: Riddle::Query.escape(l), shop: shop)
        end
      end
    end
    if params.has_key?(:affiliation)
      ShopDetail.where(shop_id: params[:shop_id], kind: "affiliation").delete_all
      if !params[:affiliation].nil?
        params[:affiliation].each do |l|
          ShopDetail.create(kind: "affiliation", value: Riddle::Query.escape(l).upcase, shop: shop)
        end
      end
    end
    if params.has_key?(:team)
      ShopDetail.where(shop_id: params[:shop_id], kind: "team").delete_all
      if !params[:team].nil?
        params[:team].each do |l|
          ShopDetail.create(kind: "team", value: Riddle::Query.escape(l), shop: shop)
        end
      end
    end
    if params.has_key?(:qa)

      ShopQAndA.where(shop_id: params[:shop_id], official: false).delete_all
      if !params[:qa].nil?
        if params[:qa].is_a? String 
          params[:qa] = JSON.parse(params[:qa])
        end
        i = 0
        params[:qa].each do |l|
          q = ShopQAndA.where(question: Riddle::Query.escape(l[:question]), shop_id: shop.id).first
          if q.nil?
            ShopQAndA.create(question: Riddle::Query.escape(l[:question]), answer: Riddle::Query.escape(l[:answer]), shop: shop, language: "en", position: i)
          else
            q.answer = Riddle::Query.escape(l[:answer])
            q.position = i
            q.save
          end
          i += 1
        end
      end
    end

    render :json => {:success => true}
  end


  def lightframe_data
    if params[:pic_ids].nil?
      render :json => {:success => false}
      return ;
    end
    result = Array.new
    #json = JSON.parse(params[:pic_ids])
    #json = JSON.parse("{pic_ids: [52630, 52107]}")
    pic_ids = params[:pic_ids]
    pic_ids.each do |pic_id|
      picture = Picture.find(pic_id)
      #title
      if !picture.notes.nil?
        title = picture.notes
      else
        title = ''
      end
      #location
      location = 'No location specified'
      if !picture.dive.nil?
        if !picture.dive.spot.nil?
          location = picture.dive.spot.country_name
          if !picture.dive.spot.region_name.nil? && !picture.dive.spot.region_name.strip.empty?
            location += ", " + picture.dive.spot.region_name
          end
          location += ", " + picture.dive.spot.name
        end
      end
      #date_camera
      date_camera = picture.created_at.strftime("%F")
      if !picture.exif_data["Model"].nil?
        begin 
          date_camera += " - Camera: " + picture.exif_data["Model"].to_s 
        rescue
        end
      end
      #user_name
      user_name = ''
      if !picture.user.first_name.nil?
        user_name = picture.user.first_name
      else
        user_name = picture.user.nickname   
      end 
      #qualification
      qualification = ''
      if picture.user.qualifications["featured"].nil? || picture.user.qualifications["featured"].empty?
        qualification = 'Scuba Diver'
      else
        qualification = picture.user.qualifications["featured"].first["org"] unless ['Other', 'Self Assessed', 'Organization'].include?(picture.user.qualifications["featured"].first["org"])
        qualification += ' ' + picture.user.qualifications["featured"].first["title"]
      end
      #former_loc
      former_loc = 'Dived in: '
      if picture.user.dived_location_list.nil? || picture.user.dived_location_list.length == 0
        former_loc += 'No dives logged yet'
      else
        former_loc += picture.user.dived_location_list
      end
      #thread_identifier
      if !picture.dive.nil?
        thread_identifier = picture.dive.class.name + '/' + picture.dive.shaken_id
      else
        thread_identifier = 'Picture/' + picture.id.to_s
      end
      #species
      species = []
      picture.eolcnames.each do |elem|
        species << elem.to_hash
      end
      picture.eolsnames.each do |elem|
        species << elem.to_hash
      end

      data = {
          :id => picture.id,
          :large => picture.large,
          :fullpermalink => picture.fullpermalink,
          :title => title,
          :location => location,
          :date_camera => date_camera,
          :user_pic => picture.user.picture,
          :user_id => picture.user.id,
          :user_name => user_name,
          :qualification => qualification,
          :former_loc => former_loc,
          :thread_identifier => thread_identifier,
          :species => species,
          :disqus_count => -1,
          :player_big => picture.player('80%','80%')
        }
      result.push(data)
    end
    render :json => {:success => true, :data => result}
  end
end