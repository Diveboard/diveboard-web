class FishFrequency < ActiveRecord::Base
  has_many :eolsnames, :primary_key => 'gbif_id', :foreign_key => 'gbif_id'

  def fishmap

    if params[:snid].nil? then
      render :text => "Missing parameter", :layout => false
      return
    end

    cached_directory = "public/map_images"
    cached_filename = "#{cached_directory}/#{params[:snid].to_i}.kml"

    logger.debug "Checking for cached data in #{cached_filename}"
    if File.exists?(cached_filename) then
      logger.debug "Using cached file #{cached_filename}"
      render :layout => false, :content_type => "application/vnd.google-earth.kml+xml", :file => cached_filename
      return
    end

    start_index = 0
    continue_request = true
    @map = {}

    while continue_request do

      eolsname = Eolsname.find(params[:snid].to_i)
      if eolsname.nil? then
        render :text => "No species found", :layout => false
        return
      end

      gbif_id = eolsname.gbif_id
      if gbif_id.nil? then
        render :text => "Unknown species", :layout => false
        return
      end

      url = "http://data.gbif.org/ws/rest/occurrence/list?startindex=#{start_index}&coordinatestatus=true&taxonconceptkey="
      url += Eolsname.find(params[:snid].to_i).gbif_id.to_s

      #url = "http://data.gbif.org/ws/rest/occurrence/list?startindex=#{start_index}&coordinatestatus=true&scientificname="
      #url += CGI.escape(params[:sname])
      #url += "*"

      continue_request = false

      logger.debug "Calling #{url}"
      document = Net::HTTP.get(URI.parse(url))
      gbifdata = Nokogiri::XML(document)

      gbifdata.xpath('//gbif:summary').each { |summary|
        if !summary["next"].nil? then
          continue_request = true
          start_index = summary["next"].to_i
        end
      }


      gbifdata.xpath('//to:TaxonOccurrence').each { |occurrence|

        this_lat = nil
        this_lng = nil
        occurrence.xpath('.//to:decimalLatitude').each { |lat|
          this_lat = (lat.content().to_f / 2).round(0).to_i * 2
        }
        occurrence.xpath('.//to:decimalLongitude').each { |lng|
          this_lng = (lng.content().to_f / 2).round(0).to_i * 2
        }

        if this_lat.nil? || this_lng.nil? then next end

        if @map[this_lat.to_i].nil?  then @map[this_lat.to_i] = {} end
        if @map[this_lat.to_i][this_lng.to_i].nil? then
          @map[this_lat.to_i][this_lng.to_i] = 1
        else
          @map[this_lat.to_i][this_lng.to_i] += 1
        end
      }
    end

    logger.debug Time.now

    rendered_kml = render :layout => false, :content_type => "application/vnd.google-earth.kml+xml"

    begin
      logger.debug "Checking the directory #{cached_directory} exists for #{cached_filename}"
      if !File.directory? cached_directory then
        logger.debug "Creating directory #{cached_directory}"
        Dir::mkdir(cached_directory)
      end

      logger.debug "Storing the generated content in #{cached_filename}"
      File.open(cached_filename, 'w'){|f|
        f.write(rendered_kml.first);
      }
    rescue

    end
  end
end

