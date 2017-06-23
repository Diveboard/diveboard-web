require 'open-uri'


## populate columns
Country.all.each_with_index do |country, i|
  if i>=1 && country.nesw_bounds.nil?
    name = URI.escape country.cname
    puts "Processing country: #{name}"
    counter = 0
    begin
      if counter != 0
        sleep(3.seconds)
      end
      counter +=1
      data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{name}&sensor=false")
      jsondata = JSON.parse(data.read)
      if jsondata["status"] == "OVER_QUERY_LIMIT"
        puts "OVER QUERY LIMIT - GAME OVER"
        exit
      end
    end while jsondata["status"] != "OK"
    
    nesw_bounds = (jsondata["results"][0]["geometry"]['bounds']).to_json
    country.nesw_bounds = nesw_bounds
    country.save
    sleep(2)
  end
end

Region.all.each_with_index do |region, i|
  if i>=1 && region.nesw_bounds.nil?
    name = region.name.to_url.gsub(" ","+").gsub("'","-").gsub(",","").gsub("-","+")
    puts "Processing region: #{name}"

    counter = 0
    begin
      if counter != 0
        sleep(3.seconds)
      end
      counter +=1
      data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{name}&sensor=false")
      jsondata = JSON.parse(data.read)
      if jsondata["status"] == "OVER_QUERY_LIMIT"
        puts "OVER QUERY LIMIT - GAME OVER"
        exit
      end
    end while (jsondata["status"] != "OK" && jsondata["status"] != "ZERO_RESULTS")

    if jsondata["status"] == "ZERO_RESULTS"
      puts "NOT FOUND !"
    else
      
      if !jsondata["results"][0]["geometry"]["bounds"].nil?
        nesw_bounds =  "#{jsondata["results"][0]["geometry"]["bounds"]["northeast"]["lat"]},#{jsondata["results"][0]["geometry"]["bounds"]["northeast"]["lng"]},#{jsondata["results"][0]["geometry"]["bounds"]["southwest"]["lat"]},#{jsondata["results"][0]["geometry"]["bounds"]["southwest"]["lng"]}".gsub(" ","")
      elsif !jsondata["results"][0]["geometry"]["viewport"].nil?
       nesw_bounds =  "#{jsondata["results"][0]["geometry"]["viewport"]["northeast"]["lat"]},#{jsondata["results"][0]["geometry"]["viewport"]["northeast"]["lng"]},#{jsondata["results"][0]["geometry"]["viewport"]["southwest"]["lat"]},#{jsondata["results"][0]["geometry"]["viewport"]["southwest"]["lng"]}".gsub(" ","")
      else
       puts "NO BOUNDS OR VIEWPORT"
       nesw_bounds = nil
      end
      
      if nesw_bounds.match(/^[0-9\.\,\-]*$/)
        ##good data
        region.nesw_bounds = nesw_bounds
        region.save
      end
    end
    sleep(2)
  end
end

Location.all.each_with_index do |location, i|
  if i>=1 && location.nesw_bounds.nil?
    if location.country.nil?
      name = region.name.to_url.gsub(" ","+").gsub("'","-").gsub(",","").gsub("-","+")
    else
      name = location.country.cname.to_url.gsub(" ","+").gsub("'","-").gsub("-","+")+"+,+"+region.name.to_url.gsub(" ","+").gsub("-","+").gsub("'","-").gsub(",","")
    end
    puts "Processing location: #{name}"
    
    
    counter = 0
    begin
      if counter != 0
        sleep(3.seconds)
      end
      counter +=1
      data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{name}&sensor=false")
      jsondata = JSON.parse(data.read)
      
      if jsondata["status"] == "OVER_QUERY_LIMIT"
        puts "OVER QUERY LIMIT - GAME OVER"
        exit
      end
      
    end while (jsondata["status"] != "OK" && jsondata["status"] != "ZERO_RESULTS")

    if jsondata["status"] == "ZERO_RESULTS"
      puts "NOT FOUND !"
    else
      
      if !jsondata["results"][0]["geometry"]["bounds"].nil?
        nesw_bounds =  "#{jsondata["results"][0]["geometry"]["bounds"]["northeast"]["lat"]},#{jsondata["results"][0]["geometry"]["bounds"]["northeast"]["lng"]},#{jsondata["results"][0]["geometry"]["bounds"]["southwest"]["lat"]},#{jsondata["results"][0]["geometry"]["bounds"]["southwest"]["lng"]}".gsub(" ","")
      elsif !jsondata["results"][0]["geometry"]["viewport"].nil?
       nesw_bounds =  "#{jsondata["results"][0]["geometry"]["viewport"]["northeast"]["lat"]},#{jsondata["results"][0]["geometry"]["viewport"]["northeast"]["lng"]},#{jsondata["results"][0]["geometry"]["viewport"]["southwest"]["lat"]},#{jsondata["results"][0]["geometry"]["viewport"]["southwest"]["lng"]}".gsub(" ","")
      else
       puts "NO BOUNDS OR VIEWPORT"
       nesw_bounds = nil
      end
      
      if nesw_bounds.match(/^[0-9\.\,\-]*$/)
        ##good data
        location.nesw_bounds = nesw_bounds
        location.save
      end
    end
    sleep(2)
  end
end
