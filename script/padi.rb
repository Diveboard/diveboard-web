#!/usr/bin/ruby
# encoding: UTF-8

require 'net/http'
require 'uri'

uri = URI.parse(URI.escape("http://www.padi.com/scuba/locate-a-padi-dive-shop/default.aspx"))
http = Net::HTTP.new(uri.host, uri.port)
#http.use_ssl = true
http.read_timeout = 3600
request = Net::HTTP::Post.new(uri.path)
request.set_form_data({"subgurim_Id" => "subgurim_GMap1", "subgurim_Args" => "5|subgurim_GMap1;(0.86832824998009, 0.3126220703125);(-89.89000815866184, -179.9999999);(89.67255514839676, 179.9999928125);6;m|"})
response = http.request(request)

line = response.body.force_encoding("utf-8")

colors = {}
spots = {}


line.scan(/img([0-9]*).image = "images\/([^"]*).png";/) { |img_id, color|
  colors[img_id.to_i] = color
}

line.scan(/marker_subgurim_([0-9]*)_ = new GMarker\(new GLatLng\(([-0-9.E]*),([-0-9.E]*)\),{icon:img([0-9]*)}\);/) { |id, lat, lng, img|
  spots[id.to_i] = {:lat => lat.to_f, :lng => lng.to_f, :img => colors[img.to_i]}
}

line.scan(/marker_subgurim_([0-9]*)_.openInfoWindowHtml\('(.*?)'\); }\);mManager_subgurim_/) { |id, desc|
  desc.sub!(/<div.*?>/, "") 
  desc.sub!(/<\/div>$/, "") 
  desc.gsub!(/<br \/><a style=cursor:pointer id=href.*/, "")
  if (!spots[id.to_i].nil?) then spots[id.to_i][:desc] = desc end
}

spots.each{|spot_id, spot|
  begin
    if !spot.nil? then
      #puts spot[:desc].gsub("<br />", "\n")
      name = spot[:desc].match(/^(.*?) *S-[0-9]* *<br/)
      name.nil? || name = name[1]
      name.nil? || name.gsub!('\\', "'")
      tel = spot[:desc].match(/>Ph: *(.*?)<br/)
      tel.nil? || tel = tel[1]
      mail = spot[:desc].match(/mailto: *([-a-zA-Z0-9_+@.=]*)/)
      mail.nil? || mail = mail[1]
      web = spot[:desc].match(/>http:\/\/(.*?)<\/a>/)
      web.nil? || web = web[1]
      address = spot[:desc].match(/^.*? *S-[0-9]* *<br \/>(.*?)(Ph:|Fax:|<a)/)
      address.nil? || address = address[1].gsub("<br />", "\n").gsub("\\", "'")

      s = Shop.new
      s.source = "PADI"
      s.source_id = spot_id
      if spot[:img] == "yellow" then
        s.kind = "Career Development Dive Centers, 5 Star Instructor Development Dive Centers and Resorts"
      elsif spot[:img] == "red" then
        s.kind = "5 Star Dive Centers and Dive Resorts"
      elsif spot[:img] == "purple" then
        s.kind = "Dive Shops, Dive Resorts, Dive Boats and Recreational Facilities"
      end
      s.name = name
      s.address = address
      s.email = mail
      s.web = web
      s.phone = tel
      s.lat = spot[:lat]
      s.lng = spot[:lng]
      s.desc = spot[:desc]
      s.save

    end
  rescue Exception => e  
    puts "ERROR with following record : #{e.message}"
    puts "#{e.backtrace.inspect}"
    puts name
    puts address
    puts mail
    puts web
    puts tel
    puts spot[:lat]
    puts spot[:lng]
    puts spot[:desc]
    puts nil
  end
}
