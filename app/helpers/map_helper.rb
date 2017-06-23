require 'net/http'

module MapHelper

  def MapHelper.country_from_coord(lat, lng)
    begin
      url = "http://ws.geonames.org/countryCode?lat=#{lat}&lng=#{lng}&radius=20&type=json"
      Rails.logger.debug "Calling #{url}"
      uri = URI(url)
      json = Net::HTTP.get(uri)
      Rails.logger.debug "Geonames said: #{json}"
      response = JSON.parse(json)

      #Handling Errors
      if !response['status'].nil? then
        #Error 15 is no country found
        if response['status']['value'] == 15 then
          return nil
        else
          raise DBTechnicalError.new "Geonames call failed", message: response['status']['message'] if response.include?('status')
        end
      end

      # Looking for the corresponding country
      country = Country.where(:ccode => response['countryCode'].upcase).first
      raise DBArgumentError.new "No country with given code - Missing country in DB ?", country_code: response['countryCode'].upcase if country.nil?
      return country
    rescue
      Rails.logger.error "Geonames call failed : #{$!.message}"
      Rails.logger.debug $!.backtrace.join("\n")
      return nil
    end
  end

end
