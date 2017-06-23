require 'open-uri'
require 'net/http'


def remote_file_exists?(url)
  url = URI.parse(url)
  Net::HTTP.start(url.host, url.port) do |http|
    return http.head(url.request_uri).code == "200"
  end
end


##Create the entry for each fish
Eolsname.where("picture >= 1").each do |fish|
  ## Get the first non-404 picture listed
  data = JSON.parse(fish.data)
  url = nil
  credits = nil
  data.each do |record|
    if !record["mediaURL"].nil? && remote_file_exists?(record["mediaURL"])
      url = record["mediaURL"]
      credits = record["agents"]
      credits.each do |credit|
        credit["license"] = record["license"]
      end
      break
    end
  end
  
  ## Store it ASYNCHRONOUSLY and bind it to the eolsname
  
  
  
  
  
end