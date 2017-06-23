require 'open-uri'

def get_elt res, which, what
  res.each do |h|
    return h[what] if h['types'].include?(which)
  end
  return nil
end



## FIRST: populate google_geocode column
Shop.where(:city => nil, :google_geocode => nil).where("address is not null and address <> ''").each_with_index do |shop, i|
  sleep(3)
  puts "\n\nProcessing shop: #{shop.name} (##{shop.id})\n#{shop.address}"
  data = open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.escape shop.address}&sensor=false")
  jsondata = JSON.parse(data.read)
  puts jsondata.to_json
  if jsondata["status"] == "OVER_QUERY_LIMIT"
    puts "OVER QUERY LIMIT - GAME OVER"
    exit
  end

  shop.google_geocode = jsondata.to_json
  shop.save
end

## SECOND: update the data columns depending on the precision of the return
Shop.all.each do |s|
  begin
    next if s.google_geocode.blank?
    res = JSON.parse(s.google_geocode)["results"].first
    next if res.nil?
    approx = res['geometry']['location_type'] rescue nil 
    case approx
    when "ROOFTOP" then
      s.country_code ||= get_elt res['address_components'], 'country', 'short_name'
      s.city ||= get_elt res['address_components'], 'locality', 'long_name'
      s.lat ||= res['geometry']['location']['lat']
      s.lng ||= res['geometry']['location']['lng']
    when "RANGE_INTERPOLATED" then
      s.country_code ||= get_elt res['address_components'], 'country', 'short_name'
      s.city ||= get_elt res['address_components'], 'locality', 'long_name'
      s.lat ||= res['geometry']['location']['lat']
      s.lng ||= res['geometry']['location']['lng']
    when "GEOMETRIC_CENTER" then
      s.country_code ||= get_elt res['address_components'], 'country', 'short_name'
      s.city ||= get_elt res['address_components'], 'locality', 'long_name'
      #s.lat ||= res['geometry']['location']['lat']
      #s.lng ||= res['geometry']['location']['lng']
    when "APPROXIMATE" then
      s.country_code ||= get_elt res['address_components'], 'country', 'short_name'
      s.city ||= get_elt res['address_components'], 'locality', 'long_name'
      #s.lat ||= res['geometry']['location']['lat']
      #s.lng ||= res['geometry']['location']['lng']
    end
    s.save!
  rescue
    puts "#{s.id}: #{$!.message}"
  end
end; nil


## Production exceptions on 10/10/2012
# 2464: Invalid country code
# 2465: Invalid country code
# 2542: Invalid country code
# 2544: Invalid country code
# 2546: Invalid country code
# 2547: Invalid country code
# 2549: Invalid country code
# 2551: Invalid country code
# 2552: Invalid country code
# 2555: Invalid country code
# 2568: Invalid country code
# 2571: Invalid country code
# 2576: Invalid country code
# 2583: Invalid country code


