module SearchHelper




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

  def SearchHelper.spot_simmilar_search userid, name, country_name, location_name, limit=20
    name = name.gsub(/[^a-zA-Z0-9]/," ").gsub(/\ +/, " ") ##replace messy chars by spaces
    if name.empty? || name == " " || country_name.empty? || country_name == " " || location_name.empty? || location_name == " "  then return [] end
  
    keywords = []
    name.split(" ").each do |term|
      if term.match(/[a-zA-Z0-9]/)
        keywords.push("#{term}")
      end
    end
    
    location_keywords = []
    location_name.split(" ").each do |term|
      if term.match(/[a-zA-Z0-9]/)
        location_keywords.push("#{term}")
      end
    end
  
    found_ids = {}
    sanitized_result = []
    
    country_found = Country.where("lower(cname) in (:cname)", {:cname => country_name.downcase})
    country_list = []
    country_found.each { |country|
      country_list.push(country.id)
    }
    Rails.logger.debug "Countries for simmilar search: #{country_list}"
    location_found = Location.where("lower(name) in (:name)", {:name => location_name.downcase})
    location_list = []
    location_found.each { |location|
      location_list.push(location.id)
    }
    #try simmilar locations
    location_found = Location.where((['name LIKE ?'] * location_keywords.size).join(' OR '), *location_keywords.map{ |key| "%#{key}%" })
    location_found.each { |location|
      location_list.push(location.id)
    }
    
    Rails.logger.debug "Locations for simmilar search: #{location_list}"
    
    r = Spot.where((['name LIKE ?'] * keywords.size).join(' OR '), *keywords.map{ |key| "%#{key}%" }).where("country_id in (:countries) and location_id in (:locations)", {:countries => country_list, :locations => location_list}).limit(limit)
    result = r.to_a.reject {|s| s.blank? || found_ids[s.id]}
    result.each do |s| found_ids[s.id] = true end
    sanitized_result += SearchHelper.sanitize_spot_list(userid, result)
    sanitized_result.uniq!
    #complete with research without location
    if result.count < limit
      r = Spot.where((['name LIKE ?'] * keywords.size).join(' OR '), *keywords.map{ |key| "%#{key}%" }).where("country_id in (:countries)", {:countries => country_list}).limit(limit)
      result = r.to_a.reject {|s| s.blank? || found_ids[s.id]}
      result.each do |s| found_ids[s.id] = true end
      sanitized_result += SearchHelper.sanitize_spot_list(userid, result)
      sanitized_result.uniq!
    end
    Rails.logger.debug "found #{result.count} spots" and return sanitized_result[0...limit] if sanitized_result.length > limit
  
    return sanitized_result
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
