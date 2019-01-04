module SearchHelper


  def SearchHelper.gmaps_meter_per_px lat, long, zoom
    return 156543.03392 * Math.cos(lat * Math::PI / 180) / (zoom*zoom)
  end


  def SearchHelper.spot_text_search userid, text, limit=50
    text = text.gsub(/[^a-zA-Z0-9]/," ").gsub(/\ +/, " ") ##replace messy chars by spaces
    if text.empty? || text == " " then return [] end

    query = ""
    text.split(" ").each do |term|
      if term.match(/[a-zA-Z0-9]/)
        if query != "" then query += " | " end
        query += "#{term}"
      end
    end

    found_ids = {}
    sanitized_result = []
    batch_size = 50

    pages = Spot.search(text, :per_page => batch_size, :populate => false).total_pages
    (1..pages).each do |page|
      r = Spot.search(text, :per_page => batch_size, :page => page , :populate => true)
      result = r.to_a.reject {|s| s.blank? || found_ids[s.id]}
      result.each do |s| found_ids[s.id] = true end
      sanitized_result += SearchHelper.sanitize_spot_list(userid, result)
      sanitized_result.uniq!
      Rails.logger.debug "found #{result.count} spots" and return sanitized_result[0...limit] if sanitized_result.length > limit
    end

    pages = Spot.search("\"#{text}\"~10", :per_page => batch_size, :populate => false).total_pages
    (1..pages).each do |page|
      r = Spot.search("\"#{text}\"~10", :per_page => batch_size, page: page, :populate => true)
      result = r.to_a.reject {|s| s.blank?}
      sanitized_result += SearchHelper.sanitize_spot_list(userid, result)
      sanitized_result.uniq!
      Rails.logger.debug "found #{result.count} spots" and return sanitized_result[0...limit] if sanitized_result.length > limit
    end

    pages = Spot.search("#{query}", :per_page   => batch_size, :populate => false).total_pages
    (1..pages).each do |page|
      r = Spot.search("#{query}", :per_page   => batch_size, :populate => true)
      result = r.to_a.reject {|s| s.blank?}
      sanitized_result += SearchHelper.sanitize_spot_list(userid, result)
      sanitized_result.uniq!
      Rails.logger.debug "found #{result.count} spots" and return sanitized_result[0...limit] if sanitized_result.length > limit
    end

    return sanitized_result
  end

  def SearchHelper.spot_simmilar_search userid, name, lat, long, zoom, limit=20
    if (name.empty? || name == " ")
      name = ""
    else
      name = name.gsub(/[^a-zA-Z0-9]/," ").gsub(/\ +/, " ") ##replace messy chars by spaces
    end
    if lat  == 0 || long == 0 || zoom == 0  then return [] end
  
    found_ids = {}
    sanitized_result = []
    
    lat = (lat * 0.0174532925).to_f
    lng = (long * 0.0174532925).to_f
    distance=((SearchHelper.gmaps_meter_per_px lat, long, zoom)*660).round() #Calculate radius distance based on the zoom level
    Rails.logger.debug "Checking spot near #{lat} : #{lng} with zoom #{zoom} (#{distance} m radius)"
    result = Spot.search name, :geo => [lat, lng], :with => {:geodist => 0.0..distance}, :order => "geodist ASC, weight() DESC", :limit=> limit*10, :match_mode => :extended
    #resulta = result
    resulta = SearchHelper.sanitize_spot_list(userid, result)
    count = resulta.length
    Rails.logger.debug "Found #{count} spots"
    
    return resulta;
  end

  #search from lat and long given in degrees and a distance around in meters
  def SearchHelper.spot_geo_search userid, lat, long, distance=50_000.0, limit=50
    lat = (lat * 0.0174532925).to_f
    lng = (long * 0.0174532925).to_f
    Rails.logger.debug "Checking spot near #{lat} : #{lng}"
    result = Spot.search "", :geo => [lat, lng], :with => {:geodist => 0.0..distance}, :order => "geodist ASC, weight() DESC", :per_page => (limit*2), :match_mode => :extended
    return SearchHelper.sanitize_spot_list(userid, result[0..limit])
  end

  def SearchHelper.sanitize_spot_list userid, spot_array
    ## will ensure @user (wether it's nil or not has access to those spots
    sanitized_array = []
    spot_array.each do |s|
      if s.is_visible_for?(userid)
        sanitized_array.push s
      end
    end
    return sanitized_array
  end



end
