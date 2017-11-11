require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'zip/zip'
require 'rubyXL'
require 'tempfile'
require 'bindata'

def normalize_unit(value, unit)

  if value.nil? || (value.respond_to?(:empty?) && value.empty?) then return nil end

  value_1 = value.to_f

  case unit
  #Lengths are normalized in meters
  when 'M' then
    return value_1
  when 'ThM' then
    return value_1
  when 'Ft' then
    return value_1*0.3048
  when 'ThFt' then
    return value_1*0.3048
  when 'MFWA' then
    return value_1
  when 'MFWG' then
    return value_1
  when 'MSWG' then
    return value_1
  when 'FFWG' then
    return value_1*0.3048
  when 'FSWG' then
    return value_1*0.3048
  when 'FFWA' then
    return value_1*0.3048

  #Temperatures are normalized in Celsius
  when "C" then
    return value_1
  when "F" then
    return (value_1-32)*5/9
  when "K" then
    return (value_1-273.15)
  #Pressures are normalized in bar
  when "Bar" then
    return value_1
  when "mBar" then
    return value_1 / 1000
  when "Kgsc" then
    return value_1 * 0.9804
  when "ATA" then
    return value_1 * 1.01295
  when "Pa" then
    return value_1 / 100000
  when "kPa" then
    return value_1 / 100
  when "MPa" then
    return value_1 * 10
  when "PSI" then
    return value_1 * 0.06893
  when "PSIA" then
    return value_1 * 0.06893

  #Volumes are normalized in liters
  when "L" then
    return value_1
  when "CF" then
    return value_1 * 28.3168466
  else
    #todo throw exception

  end

end

class Divelog
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :diver, :dives, :initial_data

  #FORMATS SUPPORTED

  #     Format     Read    Write
  # ------------- ------- -------
  # Database        Yes     Yes
  # UDCF            Yes     Yes
  # ZXL (DAN DL7)   Yes     Yes
  # SDE             Yes     No
  # XLS             Yes     No
  # ASD             Yes     No
  # TXT (CRESSI)    Yes     No
  # UDDF            Yes     No  


  #dive_number_in_export = number, starting at 0
  #"internal_sequence" = number
  #"beginning" = time object => dive.time_in
  #"maximum_depth" => float => dive.maxdepth
  #"reach_surface" => time object => dive.time_in + dive.duration
  #duration = integer in number of seconds => dive.duration
  #"min_water_temp" = float #OPTIONAL => dive.temp_bottom
  #"max_water_temp" = float #OPTIONAL => dive.temp_surface
  #"air_temperature" = float OPTIONAL => ????
  #"dive_comments" = string OPTIONAL
  #site : string optional (mandatory if place is not null) if place is not null, then site contains only the dive site name
  #place : string optional

  #sample:
  #time
  #depth
  #ascent_violation => violation of the ascention speed - T/F - TODO: check presence
  #deco_violation => violation of decompression ceiling or level - T/F - TODO: check presence
  #deco_start => a decompression ceiling first appeared during the dive - T/F - TODO: check presence
  #current_water_temperature => current water temperature - TODO: check presence
  #surface_event => the diver surfaced (generated from computer only) - T/F
  #bookmark => a bookmark has been inserted here by the diver during his dive - T/F
  #heart_beats => optional
  #main_cylinder_pressure => optional
  #gas_switch => 1.0
  #guide => divemaster name
  #buddies => array of hashes for db_buddies= : db_id | id | fb_id?, email?, name

  #tanks:
  #'material' => tank.material,
  #'volume' => tank.volume,
  #'multitank' => tank.multitank,
  #'o2' => % of o2 - integer (eg: 21)
  #'n2' => tank.n2,
  #'he' => tank.he,
  #'p_start' => tank.p_start,
  #'p_end' => tank.p_end,
  #'time_start' => tank.time_start

  def initialize(attributes = {})
    @initial_data = nil
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end


  def persisted?
    false
  end


  def fromZXL(filepath)
    f = File.open(filepath, "rb")
    content = ""
    f.each{|line|
      content += line
    }
    f.close
    self.from_ZXL_object(content)
    return self
  end




  def from_uploaded_profiles(uploaded_profile_id, movescount_ids=nil)
    Rails.logger.debug "Starting load for #{uploaded_profile_id}"
    data = UploadedProfile.find(uploaded_profile_id)
    content = data.data.split(/\n/)
    if content.count <= 0 then
      return
    end
    if data.source == "movescount"
      self.diveFromMovescount(data,movescount_ids)
    else
      if data.log =~ /\.xlsx/ then
        Rails.logger.debug "Processing profile #{uploaded_profile_id} as XLS"
         self.from_XLS_object(data.data)
      elsif data.data =~ /FSH\|......\|[^|]*\|ZX[LU]\|/ then
        self.from_ZXL_object(data.data)
      elsif data.data =~ /<[ \t]*UDDF/i then
        self.from_UDDF_object(data.data, data.source)
      elsif data.data =~ /<profile.*udcf=/i then
        self.from_UDCF_object(data.data, data.source)
      elsif data.data =~ /<DIVE>/i then
        self.from_UDCF_object(data.data, data.source)
      elsif data.data[0..1] == "PK" then
        self.from_SDE_zip_object(data.data)
      elsif data.data[0..19] == [7,16,"CTravelTrakCEDoc"].pack("vva16")
        self.from_ASD(data.data)
      elsif data.data =~ /^Dive\ Nr/ then
        self.from_cressi_object(data.data)
      else
        Rails.logger.warn "File format not recognized UploadedProfile.find(#{uploaded_profile_id})"
        raise DBArgumentError.new "File not recognised"
      end
    end

    if !@dives.nil? then
      @dives.each { |dive|
        begin
          if dive["sample"].nil? || dive["sample"].count == 0 then
            generate_dummy_profile(dive)
          end
        rescue
        end
      }
      Rails.logger.info "Number of dives read from profile ##{uploaded_profile_id} : #{@dives.count}"
    else
      Rails.logger.info "profile ##{uploaded_profile_id} had no dives"
    end


    return self

  end

  def movescountDiveList(user_id)
    require 'net/http'
    @user = User.find(user_id)

    response = []
    stitched_response  = []

    startdate = "1900-01-01"
    urls = []
    loop_max = 30
    loop_count = 0
   
    loop do
      loop_count += 1

      count = stitched_response.length

      url = "#{MOVESCOUNT_REST_URL}/moves/private?appkey=#{MOVESCOUNT_API_KEY}&userkey=#{@user.movescount_userkey}&email=#{@user.movescount_email}&startdate=#{startdate}&enddate=#{Date.today.to_s}"
      urls.push url
      Rails.logger.debug "getting #{user_id} movescount dives through #{url}"
      raw_resp = URI.parse(url).read
      response = JSON.parse(raw_resp)
      stitched_response.push(response).flatten!.uniq!

      startdate = Time.parse(response.last["LocalStartTime"]).to_date.to_s rescue break

      break if count == stitched_response.length || loop_count > loop_max

    end

    stitched_response.reject! { |r| 
      r['ActivityID'] != 52 && r['ActivityID']!=51
    }

    uploaded_profile = UploadedProfile.new
    uploaded_profile.user_id = @user.id
    uploaded_profile.source = "movescount"
    uploaded_profile.data = JSON.generate(stitched_response)

    uploaded_profile.save!
    return uploaded_profile
  end

  def import_movescount(user_id)
    response = movescountDiveList user_id
    response.each do |r|
      if r['ActivityID'] == 52 || r['ActivityID']==53
        uploaded_profile = UploadedProfile.new
        uploaded_profile.user_id = @user.id
        uploaded_profile.source = "movescount"
        details_url = MOVESCOUNT_REST_URL+"/moves/#{r['MoveID']}?appkey=#{MOVESCOUNT_API_KEY}&userkey=#{@user.movescount_userkey}&email=#{@user.movescount_email}"
        
        json_detail = URI.parse(details_url).read

        uploaded_profile.data = json_detail
        uploaded_profile.save
        self.from_uploaded_profiles(uploaded_profile.id)
      end
    end
  end

  def diveFromMovescount(data,movescount_ids)
    require 'net/http'
    Rails.logger.debug "Movescount dives ids : #{movescount_ids}"
    @dives =[]
    @user = User.find(data.user_id)
    details = JSON.parse(data.data)
    movescount_ids.each do |id|
      Rails.logger.debug "Movescount #{details[id.to_i]}"
      d=details[id.to_i]
      dive = {}
        details_url = MOVESCOUNT_REST_URL+"/moves/#{d['MoveID']}?appkey=#{MOVESCOUNT_API_KEY}&userkey=#{@user.movescount_userkey}&email=#{@user.movescount_email}"

        json_detail = URI.parse(details_url).read

        parsed_json_details = JSON.parse(json_detail)
        #seem to be required
        dive["beginning"] = Time.parse(parsed_json_details["LocalStartTime"])
        dive["maximum_depth"] = parsed_json_details["DiveData"]["MaximumDepth"]
        dive["duration"] = parsed_json_details["Duration"].to_f

      #looks more optionnal
     #   dive['site']=
    #    dive['place']=
   #     dive['max_water_temp']=
  #      dive['min_water_temp']=
 #       dive['air_temperature']=
#        dive['dive_comments']=
        dive["number"]=parsed_json_details["DiveData"]["DiveNumberInSeries"]
        dive["guide"]=parsed_json_details["DiveData"]["DiveMaster"]
        dive["buddy"]=parsed_json_details["DiveData"]["DiveBuddy"]
        #dive['shop']
        dive["sample"] = []
        begin
          sample_url = MOVESCOUNT_REST_URL+"/moves/#{d['MoveID']}/samples?appkey=#{MOVESCOUNT_API_KEY}&userkey=#{@user.movescount_userkey}&email=#{@user.movescount_email}"

          json_sample = URI.parse(sample_url).read

          parsed_sample = JSON.parse(json_sample)
          parsed_sample['SampleSets'].each do |s| 
            sample = {}
            sample["time"] =  Time.parse(s["LocalTime"]) - dive["beginning"]
            sample["depth"] = s["Depth"]
            sample["current_water_temperature"] = s["BottomTemperature"]
            sample["main_cylinder_pressure"] = normalize_unit(s["CylinderPressure"][0] , "Pa") rescue nil
            dive["sample"].push sample
          end
        rescue
        end
        @dives[id.to_i] = dive
        Rails.logger.debug "Movescount dive #{dive}"
        #time_in: datetime, duration: integer, created_at: datetime, updated_at: datetime, user_id: integer, graph_id: string, spot_id: integer, maxdepth: decimal, notes: text, temp_surface: float, temp_bottom: float, favorite_picture: integer, privacy: integer, safetystops: string, divetype: text, favorite: boolean, uploaded_profile_id: integer, uploaded_profile_index: integer, buddies: text, visibility: string, water: string, altitude: float, weights: float, dan_data: text, current: string, dan_data_sent: text, number: integer, graph_lint: datetime, shop_id: integer, guide: string, trip_id: integer, album_id: integer, score: integer, maxdepth_value: float, maxdepth_unit: string, altitude_value: float, altitude_unit: string, temp_bottom_unit: string, temp_bottom_value: float, temp_surface_unit: string, temp_surface_value: float, weights_unit: string, weights_value: float, delta: boolean, surface_interval: integer
    end
  end

  def fromCressi(filepath)
    data = File.open( filepath,"rb")
    self.from_cressi_object(data.read)
    data.close
    return self
  end

  def from_cressi_object (content)
    @dives = []
    @diver = {}

    opened_segment = nil
    dive = nil
    timesamples = []
    depthsamples = []
    depth_pressure_unit = nil
    altitude_unit = nil
    temperature_unit = nil
    tank_pressure_unit = nil
    tank_volume_unit = nil


    unit_distance = "M"
    unit_temperature = "C"
    unit_pressure = "Bar"
    unit_volume = "L"


    @initial_data = content

    content.split(/\n/).each_with_index { |line_complete,line_number|
      #we'll go throug every line of the file and try to build a dive details data for each set of 3
      next if line_number == 0 # no need to process headers
      line_data = line_complete.split(/\t/)
      next if line_data[0] == nil ||  line_data[0] == ""## empty line
      case (line_number-1) % 3
      when 0
        #general dataset
        dive = {}
        timesamples = []
        depthsamples = []
        dive["number"] = line_data[0].to_i unless line_data[0] == ""
        dive["beginning"] = Time.parse(line_data[1]) unless line_data[1] == ""
        dive["duration"] = line_data[3].to_i unless line_data[3] == ""
        dive["maximum_depth"] = line_data[4].to_f unless line_data[4] == ""
        dive["min_water_temp"] = line_data[5].to_i unless line_data[5] == ""
        dive["max_water_temp"] = line_data[12].to_i unless line_data[12] == ""
        dive["place"] = line_data[7] unless line_data[7] == ""
        dive["site"] = line_data[8] unless line_data[8] == ""
        dive["guide"] = line_data[9] unless line_data[9] == ""
        dive["buddies"] = line_data[10].split(",") unless line_data[9] == ""
      when 1
        #time
        timesamples = line_data unless line_data[0] == ""
        Rails.logger.debug "times is #{timesamples.to_json}"
      when 2
        #depth
        depthsamples = line_data unless line_data[0] == ""
        Rails.logger.debug "depths is #{depthsamples.to_json}"
      else
        #really ? can't be anything here...
      end

      if ((line_number-1) % 3 )  == 2 then
        if timesamples != nil && timesamples.length > 0 && depthsamples != nil && depthsamples.length >0
          Rails.logger.debug "Creating samples"
          dive["sample"] = []
          timesamples.each_with_index do |t,i|
            sample = {}
            sample["time"] = t.to_i
            next if depthsamples[i] == "" || depthsamples[i] == nil
            sample["depth"] = depthsamples[i].gsub(",",".").to_f
            Rails.logger.debug "creating sample #{sample.to_json}"
            dive["sample"].push(sample)
          end
        end

        Rails.logger.debug "pushing dive : #{dive.to_json}"
        ## end of a  sequence time to push
        @dives.push dive unless dive == {}
      end
    }

  end


  def fromXLS(filepath)
    data = File.open( filepath,"r")
    self.from_XLS_object(data.read)
    data.close
    return self
  end

  def parse_bad_xls(filepath)
    sheets = []
    Rails.logger.debug "processing manually file #{filepath}"
    Zip::ZipFile.open(filepath) do |zip|
      if zip.file.file?("xl/worksheets/sheet.xml")
        sheets.push Nokogiri::XML.parse(zip.read("xl/worksheets/sheet.xml"))
      end
      i = 0
      loop do
        i += 1
        break if !zip.file.file?("xl/worksheets/sheet#{i}.xml")
        sheets.push Nokogiri::XML.parse(zip.read("xl/worksheets/sheet#{i}.xml"))
      end
    end

    raise DBArgumentError.new "Bad xlsx file" if sheets.length == 0
    worksheets = []
    sheets.each do |e|
      rows = e.xpath('//x:worksheet//x:sheetData//x:row').count
      data = Array.new
      i=0
      while i < rows do
        data[i] = Array.new
        i += 1
      end
      @@parsed_column_hash ={}
      def convert_to_index(cell_string)
        index = Array.new(2)
        index[0]=-1
        index[1]=-1
        if(cell_string =~ /^([A-Z]+)(\d+)$/)

          one = $1
          row = $2.to_i - 1 #-1 for 0 indexing
          col = 0
          i = 0
          if @@parsed_column_hash[one].nil?
            two = one.reverse #because of 26^i calculation
            two.each_byte do |c|
              int_val = c - 64 #converts A to 1
              col += int_val * 26**(i)
              i=i+1
            end
            @@parsed_column_hash[one] = col
          else
            col = @@parsed_column_hash[one]
          end
          col -= 1 #zer0 index
          index[0] = row
          index[1] = col
        end
        return index
      end
      e.xpath('//x:worksheet//x:sheetData//x:row//x:c//x:v').each do |entry|
        cell = entry.parent.attr("r")
        value = entry.text
        position = convert_to_index cell
        data[position[0]][position[1]] = value
      end

      max_row_length = 0
      data.each {|r| if r.length > max_row_length then max_row_length = r.length end}
      data.each {|r| if r.length < max_row_length then r[max_row_length-1] = nil end}
      worksheets.push data
    end
    return worksheets

  end


  def from_XLS_object(data)
    #Handles Moovescount exports
    file = Tempfile.new(['xls_profile', '.xlsx'])
    file.write(data.force_encoding('UTF-8')) ##kozz..... i don't know
    file.flush
    file.close
    original_content = RubyXL::Parser.parse file.path, :data_only => true
    nbdives = original_content.worksheets.count
    Rails.logger.debug "rubyXL found #{nbdives} worksheets"
    if nbdives == 0
      Rails.logger.debug "xls file is ill-formatted, we'll try to parse it manually"
      worksheets = self.parse_bad_xls(file.path)
      Rails.logger.debug "we manually found #{worksheets.length} worksheets"
    else
      Rails.logger.debug "xls file read by RubyXL"
      worksheets = original_content.worksheets
    end

    unit_distance = "M"
    unit_temperature = "C"
    unit_pressure = "Bar"
    unit_volume = "L"


    dive_number = 0
    @dives = []

    worksheets.each do |ws|
      if ws.class == Array
        tws = ws.transpose
      elsif ws.call == RubyXL::Worksheet
        tws = ws.extract_data.transpose ## column data
      end
      isDive = true

      dive = {}
      dive["tanks"] = []
      tank = {}
      tank['multitank'] = 0
      tank['material'] = 'steel'
      tank['time_start'] = 0
      tank['o2'] = 21
      tank['n2'] = 79
      tank['he'] = 0

      sample_interval  =1
      pressure_samples = nil
      depth_samples = nil
      divemaster = nil
      shopname = nil
      dive["sample"] = []
      tws.each_with_index do |l, line_i|
        ##processing each line
        Rails.logger.debug "Processing file line #{line_i}"
        begin
          case l[1]
          when "Activity"
            #isDive = false unless l[2].match(/Scuba|Plongée|Plongee|Tauch/i)
            ## apparently this can come with randm undocumented language... so FUCK SUUNTO
            Rails.logger.debug "XLS file is a dive: #{isDive.to_s}"
          when "StartTime [ISO8601]"
            dive["beginning"] = begin Time.parse l[2] rescue Time.now end
          when "Duration [s]"
            dive["duration"] = l[2].to_i
          when "Device"
            ##not supported
          when "Tags"
            if dive["dive_comments"].blank?
              dive["dive_comments"]= ""
            else
              dive["dive_comments"] += "\n"
            end
            l[2..-1].reject{|e| e.nil?} .each_with_index do |t,i|
              dive["dive_comments"] += ", " unless i == 0
              dive["dive_comments"] += t
            end
          when "Notes"
            if dive["dive_comments"].blank?
              dive["dive_comments"] = l[2]
            else
              dive["dive_comments"] = (l[2] + "\n" + dive["dive_comments"])
            end
          when "Mode"
            ##not supported
          when "SampleInterval"
            sample_interval = l[2]
          when "MaxDepth"
            dive["maximum_depth"] = l[2].to_i
          when "PersonalMode"
            ##not supported
          when "AltitudeMode"
            ##not supported
          when "CylinderVolume"
            tank['volume'] = l[2].to_i
          when "CylinderWorkPressure"
            ##not supported
          when "BottomTemperature"
            dive["min_water_temp"] = l[2].to_i
          when "StartTemperature"
            dive["max_water_temp"] = l[2].to_i
          when "EndTemperature"
            ##not supported
          when "DiveNumber"
            ##TODO
            dive["number"] = l[2].to_i
          when "SurfaceTime"
            ##not supported
          when "DiveMaster"
            dive["guide"] = l[2] unless l[2].blank?
          when "DiveBuddy"
            buddies = l[2..-1].reject {|e| e.blank?}
            dive["buddies"] = buddies.map{|e| {"name" => e}}
          #when "BoatName"
          #  shopname = l[2]
          when "PressureSamples"
            ##WTH is that !?
            pressure_samples = l[2..-1].reject {|e| e.nil?}
          when "DepthSamples"
            depth_samples = l[2..-1].reject {|e| e.nil?}
          when "Type"
            ##unsupported
          when "MarkTime"
            ##unsupported
          when "Depth"
            ##unsupported
          when "TankPressure"
            ##unsupported
            tank['p_start'] = (Float(l[2])/1000.0).to_i if tank['p_start'].nil?
            tank['p_end'] = (Float(l[2])/1000.0).to_i if tank['p_end'].nil?
            tank['p_start'] = (Float(l[2])/1000.0) if (Float(l[2])/1000.0) > tank['p_start']
            tank['p_end'] = (Float(l[2])/1000.0) if (Float(l[2])/1000.0) < tank['p_end']
          when "Temperature"
            ##unsupported
          end
        rescue
          Rails.logger.debug $!.message
          Rails.logger.debug $!.backtrace
        end
      end
      Rails.logger.debug "Checking sample"
      if !depth_samples.nil?
        depth_samples .each_with_index do |e, i|
            sample = {}
            sample["time"] = i * sample_interval.to_i
            sample["depth"] = e.to_i
            if !pressure_samples.nil?
              sample["main_cylinder_pressure"] = (Float(pressure_samples[i])/1000.0).to_i
            end
            dive["sample"].push(sample)
          end
      end

      begin
        tank['p_start'] = (Float(pressure_samples.first)/1000.0).to_i if (Float(pressure_samples.first)/1000.0).to_i > tank['p_start']
        tank['p_end'] = (Float(pressure_samples.last)/1000.0).to_i if (Float(pressure_samples.last)/1000.0).to_i < tank['p_end']
        dive["tanks"].push(tank)
      rescue
        Rails.logger.debug "Could not extract tank data : #{$!.message}"
      end
      dive["reach_surface"] = dive["beginning"] + dive["duration"]

      if isDive
        @dives.push dive
        Rails.logger.debug "Dive #{@dives.count-1} @ #{dive['beginning']}: #{dive['maximum_depth']} - #{dive['duration']}"
      else
        Rails.logger.debug "was not a dive...."
      end
    end

    file.unlink
  end



  def from_ZXL_object(content)

    @dives = []
    @diver = {}

    opened_segment = nil
    dive = nil
    depth_pressure_unit = nil
    altitude_unit = nil
    temperature_unit = nil
    tank_pressure_unit = nil
    tank_volume_unit = nil

    @initial_data = content

    content.split(/\n/).each { |line_complete|
      #Suunto dive manager uses NULL chars instead of CR.......
      line_complete.split(/[\000\n\r]+/).each { |line|

        #Transform the mono-multi-line into a single mono-line
        #Rails.logger.debug "Matching line on : #{line[3..3]} #{line[-1..-1]}"
        if opened_segment.nil? and line[3..3] == '{' and line[-1..-1] == '}' then
          Rails.logger.debug line
          line[3] = "|"
          line[-1] = "|"
          Rails.logger.debug line
        end

        #check if a multi-line segment is opened
        if opened_segment.nil? and line[3..3] == '{' then
            opened_segment = line[0..2]
            line.slice!(3)
        end

        #check if a multi-line (or empty) segment is opened
        if !opened_segment.nil? then
          if line[3..3] == '}' || line[0..0] == '}' then
            if line[0..2] == opened_segment then
              opened_segment = nil
              next
            else
              opened_segment = nil
              next
            end
          else
            line = opened_segment + line
          end
        end

        #handling empty lines
        if line.length <= 3 then
          next
        end

        #Rails.logger.debug line

        #Handling the content
        fields = line.split('|')
        case fields[0]
        when "FSH"

          if fields[1] != "^~<>{}" then
            #format error
          end

          application = fields[2]

          type_of_file = fields[3]
          if type_of_file != "ZXL" and type_of_file != "ZXU" then
            #error in format
          end

          file_creation_date = fields[4]

        when "ZRH"

          Rails.logger.debug line
          if fields[1] != "^~<>{}" then
            #format error
          end
          computer_model = fields[2] #computer_model is a code defined in spec
          computer_serial = fields[3]
          depth_pressure_unit = fields[4]
          altitude_unit = fields[5]
          temperature_unit = fields[6]
          tank_pressure_unit = fields[7] #OPTIONAL
          tank_volume_unit = fields[8] #OPTIONAL

        when "ZPD"

          #NOTE from DAN spec: Consider this REQUIRED!
          #Diver should obtain this from DAN by filing one time Enrollment form available at
          #https://www.diversalertnetwork.org/research/projects/pde/enroll/index.asp
          @diver["id"] = fields[1] #OPTIONAL
          @diver["internal_id"] = fields[2]
          @diver["license"] = fields[3] #OPTIONAL
          @diver["dan_member_number"] = fields[4] #OPTIONAL
          @diver["name"] = fields[5]
          @diver["alias"] = fields[6] #OPTIONAL
          @diver["mothers_name"] = fields[7] #OPTIONAL
          @diver["date_of_birth"] = fields[8]
          @diver["birth_place"] = fields[9] #OPTIONAL
          @diver["sex"] = fields[10] #Value: 0 - missing; 1 - female; 2 - male; 3 - other
          @diver["weight"] = fields[11] #|<quantity (NM)> ^ <units (CE)>| Unit: 1 = lb; 2 = kg
          @diver["height"] = fields[12] #|<quantity (NM)> ^ <units (CE)>| Unit: 1 = inches; 2 = cm
          @diver["year_first_certification"] = fields[13] #OPTIONAL
          @diver["certification"] = fields[14] #OPTIONAL Values: 1-Student; 2-Basic; 3-Advanced/Specialty; 4-Rescue; 5-Dive Master; 6-Instructor; 7-Technical/Cave/Deep diving; 8-Scientific; 9-Commercial; 10-Military
          @diver["number_of_dives_in_last_12_months"] = fields[15] #OPTIONAL
          @diver["number_of_dives_in_last_5_years"] = fields[16] #OPTIONAL
          @diver["medical_condition"] = fields[17] #OPTIONAL
          @diver["medication"] = fields[18] #OPTIONAL
          @diver["smoking"] = fields[19] #OPTIONAL

        when "ZPA"
          @diver["address"] = fields[1] #OPTIONAL
          @diver["phone_home"] = fields[2]
          @diver["phone_office"] = fields[3] #OPTIONAL
          @diver["email"] = fields[4] #OPTIONAL
          @diver["language"] = fields[5] #OPTIONAL
          @diver["citizenship"] = fields[6] #OPTIONAL

        when "ZAR"
          #Application reserved section : not to be handled

        when "ZDH"
          #Initiating a new dive record on the dive header ZDH
          Rails.logger.debug line
          dive = {}
          dive["sample"] = []
          dive["tanks"] = []
          dive["duration"] = 0
          dive["dive_number_in_export"] = @dives.count

          dive["export_sequence"] = fields[1]
          dive["internal_sequence"] = fields[2] #number from the computer
          dive["record_type"] = fields[3] # I= imported from computer, M=Manual
          dive["record_interval"] = fields[4]
          dive["beginning"] = Time.parse(fields[5])
          dive["air_temperature"] = normalize_unit(fields[6], temperature_unit) #OPTIONAL
          dive["tank_volume"] = normalize_unit(fields[7], tank_volume_unit) #OPTIONAL
          dive["02_mode"] = fields[8] #mandatory for rebreather
          dive["rebreather_diluant_gaz"] = fields[9] #mandatory for rebreather
          dive["site_altitude"] = normalize_unit(fields[10], altitude_unit) #OPTIONAL

        when "ZDP"
          sample = {}
          sample["time"] = (fields[1].to_f * 60).round
          sample["depth"] = normalize_unit(fields[2], depth_pressure_unit)
          sample["gas_switch"] = fields[3]
          sample["current_PO2"] = normalize_unit(fields[4], tank_pressure_unit) #required for rebreather
          sample["ascent_violation"] = fields[5] #T=true, F=false
          sample["deco_violation"] = fields[6] #T/F
          sample["current_ceil"] = fields[7] #OPTIONAL
          sample["current_water_temperature"] = normalize_unit(fields[8], temperature_unit)
          sample["warnings"] = fields[9] #OPTIONAL
          sample["main_cylinder_pressure"] = normalize_unit(fields[10], tank_pressure_unit) #OPTIONAL
          sample["diluant_cylinder_pressure"] = normalize_unit(fields[11], tank_pressure_unit) #OPTIONAL
          sample["oxygen_flow_rate"] = fields[12] #OPTIONAL
          sample["cns_toxicity"] = fields[13] #OPTIONAL
          sample["oxygen_tolerance_unit"] = fields[14] #OPTIONAL
          sample["ascent_rate"] = normalize_unit(fields[15], depth_pressure_unit) #OPTIONAL ???
          sample["heart_beats"] = fields[16] #OPTIONAL (bpm)

          if sample["time"] > dive["duration"] then
            dive["duration"] = sample["time"]
          end

          dive["sample"].push(sample)

        when "ZDT"
          Rails.logger.debug line
          trailer_export_sequence = fields[1]
          trailer_internal_sequence = fields[2]
          Rails.logger.debug fields[3].to_f
          Rails.logger.debug temperature_unit
          Rails.logger.debug depth_pressure_unit
          Rails.logger.debug normalize_unit(fields[3], depth_pressure_unit)
          dive["maximum_depth"] = normalize_unit(fields[3], depth_pressure_unit)
          dive["reach_surface"] = Time.parse(fields[4]) #end of dive date
          dive["min_water_temp"] = normalize_unit(fields[5], temperature_unit) #OPTIONAL
          dive["pressure_drop_tank"] = normalize_unit(fields[6], tank_pressure_unit) #OPTIONAL

          Rails.logger.debug "Dive times : #{dive['beginning']} -> #{dive['reach_surface']}"
          if !dive["reach_surface"].nil? && !dive["beginning"].nil? && (dive["reach_surface"] - dive["beginning"]) > dive["duration"] then
            dive["duration"] = (dive["reach_surface"] - dive["beginning"])
          end

          #storing the dive in the global array
          @dives.push(dive)
          Rails.logger.debug "Dive #{@dives.count-1} @ #{dive['beginning']}: #{dive['maximum_depth']} - #{dive['duration']}"

        when "ZDD"
          detail_export_sequence = fields[1]
          detail_internal_sequence = fields[2]
          dive["purpose"] = fields[3] #OPTIONAL
          dive["program"] = fields[4] #OPTIONAL
          dive["environment"] = fields[5]
          dive["platform"] = fields[6]
          dive["plan"] = fields[7]
          dive["table"] = fields[8] #OPTIONAL
          dive["dress"] = fields[9]
          dive["apparatus"] = fields[10]
          dive["gas_source"] = fields[11] #OPTIONAL
          dive["breathing_gas"] = fields[12] #main bottom gas
          dive["decompression"] = fields[13]
          dive["number_gas_mixes"] = fields[14]
          dive["travel_gas"] = fields[15]
          dive["bottom_gas"] = fields[16]
          dive["deco_gas"] = fields[17]
          dive["shallow_gas"] = fields[18]

        when "ZSR"
        else
          # file format not recognized
        end

      }
    }

  end

  def toZXL()


    #@dives = []
    #@diver = {}
    #
    #opened_segment = nil
    #dive = nil
    #depth_pressure_unit = nil
    #altitude_unit = nil
    #temperature_unit = nil
    #tank_pressure_unit = nil
    #tank_volume_unit = nil

    export_sequence = 1

    lines = []

    line = []
    lines.push(line)
    line.push "FSH"
    line.push "^~<>{}"
    line.push "DBOa01^1.0^C"                #Application
    line.push "ZXU"                         #TODO : provide ZXL for DAN
    line.push Time.now.strftime("%Y%m%d%H%M%S") #TODO add GMT offset


    line = []
    lines.push(line)
    line.push "ZRH"
    line.push "^~<>{}"
    line.push ""                              #TODO : fill in computer code
    line.push ""                              #TODO : fill in computer serial number
    line.push "MSWG"                          #Depth unit (always meters)
    line.push "ThM"                           #Altitude unit (always meters)
    line.push "C"                             #Temerature unit (always Celsius)
    line.push "bar"                           #Pressure unit (always bar)
    line.push "L"                             #Volume unit (always liters)

    lines.push "ZAR{}"

    @dives.each{ |dive|

      line = []
      lines.push(line)
      line.push "ZDH"
      line.push export_sequence
      line.push dive["internal_sequence"]
      line.push dive["mode"]                  #type of data : (I)mported from computer or (M)anual
      line.push "Q20S"                        #TODO: set the interval in seconds
      line.push dive["beginning"].strftime("%Y%m%d%H%M%S")
      line.push ""                            #TODO: get air temperature ?
      line.push ""                            #tank volume
      line.push ""                            #O2 mode
      line.push ""                            #Rebreather Diluent Gas
      line.push ""                            #TODO (mandatory!): Altitude

      lines.push "ZDP{"

      dive["sample"].each{ |sample|

        line = []
        lines.push line
        line.push ""                          #line begins with |
        line.push (sample["time"]/60.0)
        line.push sample["depth"]
        line.push "1.00"                      #Gas switch 1=Air
        line.push ""                          #Current PO2
        line.push sample["ascent_violation"]
        line.push sample["deco_violation"]
        line.push ""                          #Current Ceiling
        line.push sample["current_water_temperature"]
        line.push ""                          #warning number
        line.push sample["main_cylinder_pressure"]  #main cylinder pressure
        line.push ""                          #diluant cylinder pressure
        line.push ""                          #Oxygen flow rate
        line.push ""                          #CNS toxicity
        line.push ""                          #OUT
        line.push ""                          #ascent rate
        line.push sample["heart_beats"]       #heart rate
      }

      lines.push "ZDP}"

      line = []
      lines.push(line)
      line.push "ZDT"
      line.push export_sequence
      line.push dive["internal_sequence"]
      line.push dive["maximum_depth"]
      line.push dive["reach_surface"].strftime("%Y%m%d%H%M%S")
      line.push dive["min_water_temp"]
      line.push ""                            #pressure drop in main tank

      export_sequence+=1
    }

    return lines.map{|line| if line.kind_of?(Array) then line.push ""; line.join("|") else line end}.join("\n")

  end

  def dive_to_UDCF(dive, indent=false)

    if dive.nil? then return end

    udcf = "\t\t<dive>\n"
    udcf +=  "\t\t<place>#{CGI.escapeHTML(dive["location"] || '')}</place>\n"
    udcf += "\t\t<date>"+dive["beginning"].strftime("<year>%Y</year><month>%m</month><day>%d</day>")+"</date>\n"
    udcf += "\t\t<time>"+dive["beginning"].strftime("<hour>%H</hour><minute>%M</minute><second>%S</second>")+"</time>\n"

    udcf += "\t\t<surfaceinterval>0.00</surfaceinterval>\n"
    udcf += "\t\t<density>0.0</density>\n"
    udcf += "\t\t<altitude>0.0</altitude>\n"

    some_temperature = [
      begin Float(dive["air_temperature"]) rescue nil end,
      begin Float(dive["min_water_temp"]) rescue nil end,
      begin Float(dive["max_water_temp"]) rescue nil end
    ].reject(&:nil?).min
    if !some_temperature.nil? then
      udcf += "\t\t<temperature>"+some_temperature.to_s+"</temperature>\n"
    end
    #udcf += "<GASES><MIX>21</MIX></GASES>\n"
    udcf += "\t\t<timedepthmode></timedepthmode>\n"

    if dive['tanks'].blank? then
      udcf += "\t\t<gases>\n"
      udcf += "\t\t\t<mix>\n"
      udcf += "\t\t\t\t<mixname>Unknown</mixname>\n"
      udcf += "\t\t\t\t<tank>\n"
      udcf += "\t\t\t\t\t<pstart>0.00</pstart>\n"
      udcf += "\t\t\t\t\t<pend>0.00</pend>\n"
      udcf += "\t\t\t\t</tank>\n"
      udcf += "\t\t\t\t<o2>0.21</o2>\n"
      udcf += "\t\t\t\t<n2>0.79</n2>\n"
      udcf += "\t\t\t\t<he>0.00</he>\n"
      udcf += "\t\t\t</mix>\n"
      udcf += "\t\t</gases>\n"
    else
      udcf += "\t\t<gases>\n"
      begin
        dive['tanks'].each_with_index do |tank, idx|
          udcf += "\t\t\t<mix>\n"
          udcf += "\t\t\t\t<mixname>#{idx+1}</mixname>\n"
          udcf += "\t\t\t\t<tank>\n"
          udcf += "\t\t\t\t\t<tankvolume>#{tank['volume']*tank['multitank']}</tankvolume>\n"
          udcf += "\t\t\t\t\t<pstart>#{tank['p_start']}</pstart>\n"
          udcf += "\t\t\t\t\t<pend>#{tank['p_end']}</pend>\n"
          udcf += "\t\t\t\t</tank>\n"
          udcf += "\t\t\t\t<o2>#{tank['o2']/100.0}</o2>\n"
          udcf += "\t\t\t\t<n2>#{tank['n2']/100.0}</n2>\n"
          udcf += "\t\t\t\t<he>#{tank['he']/100.0}</he>\n"
          udcf += "\t\t\t</mix>\n"
        end
      rescue
        Rails.logger.error "Failed to export tanks to UDCF: #{$!.message}"
        Rails.logger.debug $!.backtrace.join "\n"
      end
      udcf += "\t\t</gases>\n"
    end


    udcf += "\t\t<samples>\n"
    udcf += "\t\t\t<switch>1</switch>\n"

    dive["sample"].each { |sample|

      if indent == true
        ## we are giving data internally and internally we are using seconds
        udcf += "\t\t\t<t>"+(((sample["time"].to_f/60*100).to_i).to_f/100).to_s+"</t>\n"
      else
        udcf += "\t\t\t<t>"+(sample["time"].to_i).to_s+"</t>\n"
      end
      udcf += "\t\t\t<d>"+sample["depth"].to_s+"</d>\n"
      if !sample["ascent_violation"].nil? && sample["ascent_violation"] == "T" then
        udcf += "\t\t\t<alarm>ascent</alarm>\n"
      end
      if !sample["deco_start"].nil? && sample["deco_start"] == "T" then
        udcf += "\t\t\t<alarm>deco</alarm>\n"
      end
      if !sample["surface_event"].nil? && sample["surface_event"] == "T" then
        udcf += "\t\t\t<alarm>surface</alarm>\n"
      end
      if sample == dive["sample"].last && sample["depth"].to_f != 0.00 then

        if indent == true
          ## we are giving data internally and internally we've used seconds instead of minutes koz we're stupid and can't read the norm
          udcf += "\t\t\t<t>"+(((sample["time"].to_f/60*100).to_i).to_f/100+0.1).to_s+"</t>\n\t\t\t<d>0.00</d>\n"
        else
          udcf += "\t\t\t<t>"+((sample["time"].to_i)+1).to_s+"</t>\n\t\t\t<d>0.00</d>\n"
        end
      end

    }
    udcf += "\t\t</samples>\n"
    udcf += "\t</dive>\n"

    #Rails.logger.debug "new UDCF built : "
    #Rails.logger.debug "#{udcf}"

    if indent == false
      Rails.logger.debug "returning non-indented UDCF file "
      return udcf.gsub("\t","").gsub("\n","").upcase
    else
      Rails.logger.debug "returning indented UDCF file "
      return udcf
    end

  end


  def toUDCF(indent=false)

    if @dives.nil? then
      return nil
    end

    udcf = "<profile udcf='1'>\n"
    udcf += "\t<units>metric</units>\n"
    udcf += "\t<device>"
    udcf += "\t\t<vendor>Diveboard</vendor>"
    udcf += "\t\t<model>Diveboard</model>"
    udcf += "\t</device>"

    @dives.each { |dive|
      udcf += "\t<repgroup>\n"
      udcf += dive_to_UDCF(dive, indent)
      udcf += "\t</repgroup>\n"
    }

    udcf += "</profile>"
    if indent == false
      Rails.logger.debug "returning non-indented UDCF file "
      Rails.logger.debug udcf.gsub("\t","").gsub("\n","").upcase
      return udcf.gsub("\t","").gsub("\n","").upcase
    else
      Rails.logger.debug "returning cleanly indented UDCF file probably for export using METRIC units(WTF)"
      Rails.logger.debug udcf
      return udcf
    end
  end

  def fromUDDF(filepath)
    f = File.open(filepath, "rb")
    content = ""
    f.each{ |line|
      content += line
    }
    f.close
    self.from_UDDF_object(content, "file")
    return self
  end

  def from_UDDF_object(original_content, source)
    @initial_data = original_content
    ## Filtering content to ignore bad UTF-8 chars. Replacing Iconv for that cause deprecated
    #ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    #content = ic.iconv(original_content + ' ')[0..-2]
    content = original_content.chars.collect { |c| (c.valid_encoding?) ? c : '' }.join
    Rails.logger.debug "Loading XML"
    uddfdata = Nokogiri::XML(content.upcase)
    #make sure all the tag names are in upper case
    ####uddfdata.traverse {|e| e.node_name = e.node_name.upcase unless e.nil? || e.node_name.nil?}
    nbdives = uddfdata.xpath('//DIVE').count
    units = "si" #all units are always SI in UDDF
    Rails.logger.debug "Using units : #{units}"

    unit_distance = "M"
    unit_temperature = "K"
    unit_pressure = "Pa"
    unit_volume = "m^3"
    
 
    time_scale = 1.0/60.0 #time in samples is always in seconds

    # Create the tanks
    tanks_list = {}
    uddfdata.xpath('//MIX').each do |mix|
      tank_name = mix["ID"] rescue next
      tanks_list[tank_name] = {} 
      tanks_list[tank_name]["name"] = mix.xpath("NAME").children.to_s rescue nil
      tanks_list[tank_name]["o2"] = mix.xpath("O2").children.to_s.to_f*100 rescue nil
      tanks_list[tank_name]["n2"] = mix.xpath("N2").children.to_s.to_f*100 rescue nil
      tanks_list[tank_name]["he"] = mix.xpath("HE").children.to_s.to_f*100 rescue nil
      tanks_list[tank_name]["ar"] = mix.xpath("AR").children.to_s.to_f*100 rescue nil
      tanks_list[tank_name]["h2"] = mix.xpath("H2").children.to_s.to_f*100 rescue nil
    end




    if nbdives > 0 then
      #we have dives, send their list
      dive_number = 0
      @dives = []
      uddfdata.xpath('//DIVE').each do |divedetail|
        dive = {}
        dive["duration"] = 0
        dive["sample"] =[]
        dive["tanks"] = []
        dive["internal_sequence"] = dive_number
        dive["dive_number_in_export"] = dive_number
        dive_number = dive_number + 1

        #######
        ## PARSE INFORMATIONBEFOREDIVE
        #######


        datetime = DateTime.parse(divedetail.xpath('INFORMATIONBEFOREDIVE/DATETIME').children.to_s) rescue DateTime.now
        date = datetime.to_date.strftime("%F")
        time = datetime.to_time.strftime("%H:%M:%S")
        dive["beginning"] = Time.parse(date + " "+time)
        dive["number"] = divedetail.xpath('INFORMATIONBEFOREDIVE/DIVENUMBER').children.to_s.to_i unless divedetail.xpath('INFORMATIONBEFOREDIVE/DIVENUMBER').empty?
        dive["altitude"] = divedetail.xpath('INFORMATIONBEFOREDIVE/ALTITUDE').children.to_s.to_f unless divedetail.xpath('INFORMATIONBEFOREDIVE/ALTITUDE').empty?
        
        
        divesite = divedetail.xpath('INFORMATIONBEFOREDIVE/LINK')["REF"].to_s.to_f unless divedetail.xpath('INFORMATIONBEFOREDIVE/LINK')["REF"].empty? rescue nil
        unless divesite.nil?
          sitename = uddfdata.xpath("//SITE[@id='#{divesite}'']/NAME").children.to_s
          sitelocation = uddfdata.xpath("//SITE[@id='#{divesite}'']/GEOGRAPHY/LOCATION").children.to_s
          sitecountry = uddfdata.xpath("//SITE[@id='#{divesite}'']/GEOGRAPHY/ADDRESS/COUNTRY").children.to_s
          sitelatitude = uddfdata.xpath("//SITE[@id='#{divesite}'']/GEOGRAPHY/LATITUDE").children.to_s.to_f
          sitelongitude = uddfdata.xpath("//SITE[@id='#{divesite}'']/GEOGRAPHY/LONGITUDE").children.to_s.to_f

          dive["site"] = "#{sitename}"
          dive["site"] += ", #{sitelocation}" unless sitelocation.empty?
          dive["site"] += ", #{sitecountry}" unless sitecountry.empty?
        end



        #######
        ## PARSE SAMPLES
        #######
        dive["tanks"] = []
        current_tank = nil
        
        tank = {}
        divedepth= []
        temperature = []
        duration = []

        divedetail.xpath('SAMPLES/WAYPOINT').each do |s|
          #Time and Depth are compulsory
          sample = {}
          sample["time"] = s.xpath("DIVETIME").children.to_s.to_f
          duration.push sample["time"]
          sample["depth"] = normalize_unit(s.xpath("DEPTH").children.to_s.to_f, unit_distance)
          divedepth.push sample["depth"]

           

          temp = normalize_unit(s.xpath("TEMPERATURE").children.to_s.to_f, unit_temperature) unless s.xpath("TEMPERATURE").empty?
          sample["current_water_temperature"] 
          temperature.push temp unless temp.nil?


          sample["ascent_violation"] = "F"
          sample["deco_violation"] = "F"
          sample["deco_start"] = "F"
          sample["bookmark"] = "F"
          sample["surface_event"] = "F"
          sample["gas_switch"] = "1.0"

          s.xpath("ALARM").each do |a|
            case a.children.to_s
            when /ASCENT/i then
              sample["ascent_violation"] = "T"
            when /DECO/i then
              sample["deco_violation"] = "T"
            when /SURFACE/i then
              sample["surface_event"] = "T"
            end
          end   

          sample["main_cylinder_pressure"] = normalize_unit(s.xpath("TANKPRESSURE").children.to_s.to_f , unit_pressure) unless s.xpath("TANKPRESSURE").children.empty?   

          begin 
            unless s.xpath("SWITCHMIX").empty?
              current_tank = s.xpath("SWITCHMIX").first["REF"]
              dive["tanks"].push tanks_list[current_tank].dup
              dive["tanks"].last['multitank'] = 1
              dive["tanks"].last['material'] = 'steel'
              dive["tanks"].last['time_start'] = sample["time"]
              dive["tanks"].last['volume'] = normalize_unit(uddfdata.xpath("//tank[@id='#{current_tank}']/TANKVOLUME").children.to_s.to_f, unit_volume) rescue 0
              if dive["tanks"].length == 1
              dive["tanks"][0]['p_start'] = sample["main_cylinder_pressure"] rescue 0
              elsif dive["tanks"].length == 2
                dive["tanks"][0]['p_end'] = sample["main_cylinder_pressure"] rescue 0
              end
            end
          rescue 
            Rails.logger.warn "Could not load Tank #{s.xpath("SWITCHMIX").to_s}"
          end


          dive["sample"].push(sample)
        end


        dive["maximum_depth"]  = divedepth.max
        dive["duration"] = duration.max
        if temperature.length == 1
          dive["max_water_temp"] = temperature[0]
        elsif temperature.length > 1
          dive["min_water_temp"] = temperature.min
          dive["max_water_temp"] = temperature.max
        end


        dive["reach_surface"] = dive["beginning"] + dive["duration"]

        @dives.push dive
        Rails.logger.debug "Dive #{@dives.count-1} @ #{dive['beginning']}: #{dive['maximum_depth']} - #{dive['duration']}"

      end
    end
  end


  def fromUDCF(filepath)
    f = File.open(filepath, "rb")
    content = ""
    f.each{ |line|
      content += line
    }
    f.close
    self.from_UDCF_object(content, "file")
    return self
  end

  def from_UDCF_object(original_content, source)
    @initial_data = original_content
    ## Filtering content to ignore bad UTF-8 chars. Replacing Iconv for that cause deprecated
    #ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    #content = ic.iconv(original_content + ' ')[0..-2]
    content = original_content.chars.collect { |c| (c.valid_encoding?) ? c : '' }.join
    Rails.logger.debug "Loading XML"
    udcfdata = Nokogiri::XML(content)
    #make sure all the tag names are in upper case
    udcfdata.traverse {|e| e.node_name = e.node_name.upcase unless e.nil? || e.node_name.nil?}
    nbdives = udcfdata.xpath('//DIVE').count
    units = udcfdata.xpath('//UNITS')
    Rails.logger.debug "Using units : #{units}"
    if units.nil? || units.length == 0 then
      unit_distance = "M"
      unit_temperature = "C"
      unit_pressure = "Bar"
      unit_volume = "L"
    elsif units[0].content.match(/imperial/i) then
      unit_distance = "Ft"
      unit_temperature = "F"
      unit_pressure = "PSI"
      unit_volume = "CF"
    elsif units[0].content.match(/metric/i) then
      unit_distance = "M"
      unit_temperature = "C"
      unit_pressure = "Bar"
      unit_volume = "L"
    elsif units[0].content.match(/si/i) then
      unit_distance = "M"
      unit_temperature = "K"
      unit_pressure = "Pa"
      unit_volume = "L"
    else #should be "METRIC", but anyway default to metric
      unit_distance = "M"
      unit_temperature = "C"
      unit_pressure = "Bar"
      unit_volume = "L"
    end

    time_scale = 1.0
    if source == "computer" || source == "computed" then
      time_scale = 1.0/60.0
    end

    if nbdives > 0 then
      #we have dives, send their list
      dive_number = 0
      @dives = []
      udcfdata.xpath('//DIVE').each do |divexml|
        dive = {}
        dive["duration"] = 0
        dive["sample"] =[]
        dive["tanks"] = []
        dive["internal_sequence"] = dive_number
        dive["dive_number_in_export"] = dive_number
        dive_number = dive_number + 1

        #Rails.logger.debug { "Dive read: #{divexml}"}
        #We need to reinit the parser, for some reason using directly divexml fails...
        #parser = Nokogiri::XML(divexml.serialize(:save_with =>0).to_s)
        uppercase_parser = Nokogiri::XML(divexml.serialize(:save_with =>0).to_s)
        if uppercase_parser.xpath('//DATE').children.count==1
          date = uppercase_parser.xpath('//DATE')[0].content
        elsif uppercase_parser.xpath('//YEAR').children.count == 1 && uppercase_parser.xpath('//MONTH').children.count == 1 && uppercase_parser.xpath('//DAY').children.count == 1 then
          date = "#{uppercase_parser.xpath('//YEAR')[0].content}-#{uppercase_parser.xpath('//MONTH')[0].content}-#{uppercase_parser.xpath('//DAY')[0].content}"
        else
          #if no date is specified, then put some default date
          date = "2000-01-01"
        end

        if uppercase_parser.xpath('//TIME').children.count==1
          time = uppercase_parser.xpath('//TIME')[0].content
        elsif uppercase_parser.xpath('//HOUR').children.count==1 && uppercase_parser.xpath('//MINUTE').children.count==1 then
          time = "#{uppercase_parser.xpath('//HOUR')[0].content}:#{uppercase_parser.xpath('//MINUTE')[0].content}"
          if !uppercase_parser.xpath('//SECOND').empty?
            time = time+":#{uppercase_parser.xpath('//SECOND')[0].content}"
          else
            time = time+":00"
          end
        else
          time = "00:00:00"
        end

        dive["beginning"] = Time.parse(date + " "+time) rescue Time.now


        begin
          uppercase_parser.xpath('//PLACE').each do |place|
            dive["site"] = place.content unless place.content =~ /^ *$/
            Rails.logger.debug "Found location in UDCF: "+ dive["site"].to_s
          end
        rescue
        end

        dive["tanks"] = []
        begin
          uppercase_parser.xpath('.//MIX').each do |mix|
            tank = {}
            tank['multitank'] = 1
            tank['material'] = 'steel'
            tank['time_start'] = 0
            tank['volume'] = normalize_unit(mix.xpath('.//TANKVOLUME').first.content, unit_volume) rescue 0
            tank['p_start'] = normalize_unit(mix.xpath('.//PSTART').first.content, unit_pressure) rescue 0
            tank['p_end'] = normalize_unit(mix.xpath('.//PEND').first.content, unit_pressure) rescue 0

            #fix for those stupids softs that export in Pa while in metric
            begin
              tank['p_start'] = normalize_unit(mix.xpath('.//PSTART').first.content, "Pa") if tank['p_start'] > 100000
            rescue
            end
            begin
              tank['p_end'] = normalize_unit(mix.xpath('.//PEND').first.content, "Pa") if tank['p_end'] > 100000
            rescue
            end

            #ignore tank if there is no o2 (less than 1%) and no start pressure....
            next if tank['p_start'] == 0 && begin (mix.xpath('.//O2').first.content.to_f*100).to_i == 0 rescue true end

            # Default to 200/50 if gas composition is provided without pressure data
            if tank['p_end'] == 0 && tank['p_start'] == 0 then
              tank['p_start'] = normalize_unit(200, "Bar")
              tank['p_end'] = normalize_unit(50, "Bar")
            end

            begin
              tank['o2'] = mix.xpath('.//O2').first.content.to_f * 100
              tank['n2'] = mix.xpath('.//N2').first.content.to_f * 100
              tank['he'] = mix.xpath('.//HE').first.content.to_f * 100
            rescue
              tank['o2'] = 21
              tank['n2'] = 79
              tank['he'] = 0
            end
            dive['tanks'].push tank
          end
        rescue
          puts $!.message
          puts $!.backtrace.join "\n"
        end

        dive["maximum_depth"] = 0.00
        uppercase_parser.xpath('//D').each do |depth|
          if normalize_unit(depth.content, unit_distance) > dive["maximum_depth"]  then
            dive["maximum_depth"] = normalize_unit(depth.content, unit_distance)
          end
        end

        if uppercase_parser.xpath('//T').empty? && uppercase_parser.xpath('//DELTA').children.count == 0 then
          # nothing can be done with this dive....
          Rails.logger.warn "Dive with no data found"

        elsif uppercase_parser.xpath('//T').empty?
          #no t ? then we've got a <DELTA>20.0</DELTA>
          delta = uppercase_parser.xpath('//DELTA')[0].content.to_f
          dive["duration"]  = uppercase_parser.xpath('//D').count * delta * 60.0 * time_scale
          depth_num = 0
          uppercase_parser.xpath('//D').each { |depth|
            sample = {}
            next_node = depth.next_sibling
            sample["time"] = (depth_num*delta).to_f * 60.0 * time_scale
            sample["ascent_violation"] = "F"
            sample["deco_violation"] = "F"
            sample["deco_start"] = "F"
            sample["bookmark"] = "F"
            sample["surface_event"] = "F"
            sample["gas_switch"] = "1.0"
            sample["depth"] = normalize_unit(depth.content, unit_distance)
            while !next_node.nil? && next_node.node_name != "D" do
              case next_node.node_name
              when /TEMPERATURE/i
                sample["current_water_temperature"] = normalize_unit(next_node.content.to_s, unit_temperature)
              when /PRESSURE/i
                sample["main_cylinder_pressure"] = normalize_unit(next_node.content.to_s, unit_pressure) unless next_node.content.to_f == 0
              when /HEARTBEAT/i
                sample["heart_beats"] = next_node.content.to_f
              when /ALARM/i
                case next_node.content
                when /ASCENT/i then
                  sample["ascent_violation"] = "T"
                when /DECO/i then
                  sample["deco_start"] = "T"
                when /MANDATORY_SAFETY_STOP_VIOLATION/i then
                  sample["deco_violation"] = "T"
                when /CEILING/i then
                  sample["deco_violation"] = "T"
                when /SAFETY STOP/i then
                  sample["deco_violation"] = "T"
                when /BOOKMARK/i then
                  sample["bookmark"] = "T"
                when /SURFACE/i then
                  sample["surface_event"] = "T"
                end
              end
              next_node = next_node.next_sibling
            end
            dive["sample"].push(sample)
            depth_num = depth_num+1
          }
        else
          uppercase_parser.xpath('//T').each { |time|
            #Rails.logger.debug "Parsing time : #{time.content.to_f}"
            if time.content.to_f*60*time_scale > dive["duration"] then
              dive["duration"] = time.content.to_f*60*time_scale
            end
            sample = {}
            next_node = time.next_sibling
            sample["time"] = time.content.to_f * 60.0 * time_scale
            sample["ascent_violation"] = "F"
            sample["deco_violation"] = "F"
            sample["deco_start"] = "F"
            sample["bookmark"] = "F"
            sample["surface_event"] = "F"
            sample["gas_switch"] = "1.0"

            while !next_node.nil? && next_node.node_name != "T" do
              #Rails.logger.debug "Parsing sibling element called : #{next_node.node_name}"
              #Rails.logger.debug "Parsing sibling element data : #{next_node.content}"
              case next_node.node_name
              when "D" then
                sample["depth"] = normalize_unit(next_node.content, unit_distance)
              when /TEMPERATURE/i
                sample["current_water_temperature"] = normalize_unit(next_node.content.to_s, unit_temperature)
              when /PRESSURE/i
                sample["main_cylinder_pressure"] = normalize_unit(next_node.content.to_s, unit_pressure) unless next_node.content.to_f == 0
              when /HEARTBEAT/i
                sample["heart_beats"] = next_node.content.to_f
              when /ALARM/i
                case next_node.content
                when /ASCENT/i then
                  sample["ascent_violation"] = "T"
                when /DECO/i then
                  sample["deco_violation"] = "T"
                when /MANDATORY_SAFETY_STOP_VIOLATION/i then
                  sample["deco_violation"] = "T"
                when /CEILING/i then
                  sample["deco_violation"] = "T"
                when /SAFETY STOP/i then
                  sample["deco_violation"] = "T"
                when /BOOKMARK/i then
                  sample["bookmark"] = "T"
                when /SURFACE/i then
                  sample["surface_event"] = "T"
                end
              end
              #Rails.logger.debug "Going to next node"
              next_node = next_node.next_sibling
              #Rails.logger.debug "On next node : #{next_node}"
            end
            dive["sample"].push(sample)
          }
        end

        boundary = 999
        temperature_found = false
        max_temp = -boundary
        min_temp = boundary
        uppercase_parser.xpath('//TEMPERATURE').each do |temp|
          temperature_found = true
          if temp.content.to_f > max_temp  then
            max_temp = temp.content.to_f
          end
          if temp.content.to_f < min_temp  then
            min_temp = temp.content.to_f
          end
        end

        if temperature_found then
          dive["min_water_temp"] = normalize_unit(min_temp.to_s, unit_temperature)
          dive["max_water_temp"] = normalize_unit(max_temp.to_s, unit_temperature)
        end

        # if we think the dive lasts more than 200 minutes, it's most probably seconds and not minutes....
        if dive["duration"] > 12000 then
          dive["duration"] /= 60.0
          dive["sample"].each do |sample|
            sample["time"] /= 60.0
          end
        end

        dive["reach_surface"] = dive["beginning"] + dive["duration"]

        @dives.push dive
        Rails.logger.debug "Dive #{@dives.count-1} @ #{dive['beginning']}: #{dive['maximum_depth']} - #{dive['duration']}"

      end
    end
  end

  def from_SDE_zip_object(original_content)
    @initial_data = original_content
    zipfile = Tempfile.new("suunto_sde")
    zipfile.binmode
    zipfile.write original_content
    zipfile.close

    @dives = []
    Zip::ZipInputStream::open(zipfile.path) { |io|
      while (entry = io.get_next_entry)
        begin
          Rails.logger.info "Parsing dive in '#{entry.name}'"
          content = io.read
          number = entry.name.to_i
          from_SDE_xml_object(content, number)
        rescue
        end
      end
    }
  end

  def from_SDE_xml_object(content, dive_number)

    data = Nokogiri::XML(content)
    data.serialize :save_with => 0  # Nokogiri::XML::Node::SaveOptions.new(0)

    dive = {}
    dive["sample"] =[]
    dive["tanks"] = []
    dive["dive_number_in_export"] = @dives.count

    begin
      dive["internal_sequence"] = data.wpath('//DIVENUMBER').first.content.to_i
    rescue
      dive["internal_sequence"] = dive_number
    end
    begin
      dive["beginning"] = Time.parse( "#{data.xpath('//DATE').first.content} #{data.xpath('//TIME').first.content}" );
    rescue
      dive["beginning"] = Time.new;
      rails.info "Using default date because of failure in date parse: #{dive['beginning']}"
    end
    begin
      dive["duration"] = (data.xpath('//SAMPLETIME').map {|t| t.content.to_i}).max
      dive["duration"] ||= data.xpath('//DIVETIMESEC').first.content.to_i rescue 0
    rescue
      dive["duration"] = 0
    end
    begin
      dive["reach_surface"] = dive["beginning"] + dive["duration"]
    rescue
      dive["reach_surface"] = dive["beginning"]
    end
    begin
      dive["air_temperature"] = Float(data.xpath('//AIRTEMP').first.content.gsub(",", "."));
    rescue
    end
    begin
      dive["min_water_temp"] = Float(data.xpath('//WATERTEMPMAXDEPTH').first.content.gsub(",", "."));
    rescue
    end
    begin
      dive["max_water_temp"] = Float(data.xpath('//WATERTEMPATEND').first.content.gsub(",", "."));
    rescue
    end
    begin
      dive["maximum_depth"] = Float(data.xpath('//MAXDEPTH')[0].content.gsub(",", "."))
    rescue
      dive["maximum_depth"] = (data.xpath('//DEPTH').map{|t| t.content.gsub(",", ".").to_f }).max
    end
    begin
      dive["dive_comments"] = data.xpath('//LOGNOTES')[0].content
      dive["dive_comments"] = nil if dive["comment"] =~ /^ *$/
    rescue
    end
    begin
      dive["site"] = data.xpath('//SITE')[0].content
      dive["site"] = nil if dive["site"] =~ /^ *$/
    rescue
    end
    begin
      dive["place"] = data.xpath('//LOCATION')[0].content
      dive["place"] = nil if dive["place"] =~ /^ *$/
    rescue
    end
    begin
      dive["guide"] = data.xpath('//DIVEMASTER')[0].content
      dive["guide"] = nil if dive["guide"] =~ /^ *$/
    rescue
    end
    begin
      dive["buddies"] = data.xpath('//PARTNER')[0].content.split /[,;&]/
      dive["buddies"].map! &:strip
      dive["buddies"].reject! do |buddy| buddy.match(/^ *$/) end
      dive["buddies"].map! {|e| {"name" => e}}
    rescue
      dive["buddies"] = nil
    end

    begin
      tank={}
      tank_volume_unit = "L"
      if data.xpath('//CYLINDERUNITS')[0].content.to_i == 0 then
        tank_volume_unit = "L"
      else
        tank_volume_unit = "CF"
      end
      tank['multitank'] = 0
      tank['time_start'] = 0
      tank['material'] = 'steel'
      tank['volume'] = normalize_unit(data.xpath('//CYLINDERSIZE')[0].content.to_i, tank_volume_unit) rescue 0
      tank['p_start'] = normalize_unit(data.xpath('//CYLINDERSTARTPRESSURE')[0].content.to_i, "mBar") rescue 0
      tank['p_end'] = normalize_unit(data.xpath('//CYLINDERENDPRESSURE')[0].content.to_i, "mBar") rescue 0
      tank['o2'] = data.xpath('//O2PCT')[0].content.to_i rescue 0
      tank['he'] = data.xpath('//HEPCT_0')[0].content.to_i rescue 0
      tank['n2'] = 100 - tank['o2'] - tank['he']

      if tank['o2'] >= 1 || tank['p_start'] >= 1 || tank['p_end'] >= 1 || tank['volume'] >= 1 then
        if tank['n2'] >= 99 then
          tank['o2'] = 21
          tank['he'] = 0
          tank['n2'] = 79
        end
        dive['tanks'].push(tank)
      end
    rescue
      Rails.logger.debug "SDE tank : $!"
    end


    #TODO Handle place //LOCATION (Gozo), //SITE (spot)

    dive["sample"] = []

    data.xpath('//SAMPLE').each do |samplexml|
      sample = Nokogiri::XML(samplexml.serialize(:save_with =>0).to_s)
      s={}
      s["ascent_violation"] = "F"
      s["deco_violation"] = "F"
      s["deco_start"] = "F"
      s["bookmark"] = "F"
      s["surface_event"] = "F"
      s["heart_beats"] = nil
      s["main_cylinder_pressure"] = nil
      s["gas_switch"] = "1.0"
      begin
        s["time"] = sample.xpath('//SAMPLETIME').first.content.to_i
      rescue
        next
      end
      begin
        s["depth"] = Float(sample.xpath('//DEPTH').first.content.gsub(",", "."));
      rescue
      end
      begin
        t = sample.xpath('//TEMPERATURE').first.content
        if t != "0" then
          s["current_water_temperature"] = Float(t.gsub(",", "."));
        end
      rescue
      end
      begin
        p = sample.xpath('//PRESSURE').first.content
        if p != "0" then
          s["main_cylinder_pressure"] = Float(p.gsub(",", "."))/1000;
        end
      rescue
      end

      begin
        (sample.xpath('//BOOKMARKTYPE').map {|t| t.content.to_i}).each do |bmk_type|
          case bmk_type
          when 126 then s["deco_start"] = "T"
          when 125 then s["surface_event"] = "T"
          when 125 then s["bookmark"] = "T"
          when 120 then s["ascent_violation"] = "T"
          end
        end
      rescue
      end

      dive["sample"].push s
    end

    @dives.push dive

  end

  # Classes for binary ASD reading
  class StupidString < BinData::BasePrimitive

    def value_to_binary_string(str)
      len = str.length
      uint16_array = str.unpack("C*")
      bytes = [0xff]
      if len == 0 then
        bytes.push 0xfe
        bytes.push 0xff
        bytes.push 0x00
      elsif len < 0xff then
        bytes.push len & 0xff
      else
        bytes.push 0xff
        bytes.push(len&0xff)
        bytes.push((len&0xff00)>>8)
      end
      uint16_array.each do |c|
        bytes.push(c&0xff)
        bytes.push((c&0xff00)>>8)
      end
      bytes.collect { |b| b.chr }.join
    end

    def read_and_return_value(io)
      cnt = 0
      value = []
      len0 = read_uint8(io)
      raise DBArgumentError.new "String pattern not recognized" unless len0 == 0xff
      len1 = read_uint8(io)
      if len1 == 0xff then
        len1 = read_uint16(io)
      elsif len1 == 0xfe then
        len1 = read_uint16(io)
        len1 >>= 8
      end

      if len1 == 0xff then
        len1 = read_uint16(io)
      end

      while cnt < len1 do
        value.push read_uint16(io)
        cnt += 1
      end

      return value.pack("C*")
    end

    def sensible_default
      []
    end

    def read_uint8(io)
      l=io.readbytes(1).unpack("C").at(0)
      return l
    end

    def read_uint16(io)
      l=io.readbytes(2).unpack("v").at(0)
      return l
    end
  end


  class ASDFile < BinData::Record
    endian :little
    uint16 :doc_version, :check_value => 7
    uint16 :doc_name_len
    string :doc_name, :read_length => :doc_name_len
    uint16 :string_id, :check_value => lambda { string_id == 0xfeff }
    stupid_string :description
    uint32 :dive_offset
    uint32 :length_units
    uint32 :temperature_unit
    uint32 :last_transfer
    uint32 :smart_type
    uint32 :smart_subtype
    uint32 :smart_id
    uint32 :feature_set
    uint32 :selection
    uint16 :suit_count
    array  :suits, :type => :stupid_string, :initial_length => :suit_count
    uint16 :weather_count
    array  :weathers, :type => :stupid_string, :initial_length => :weather_count
    uint16 :water_count
    array  :waters, :type => :stupid_string, :initial_length => :water_count
    uint16 :surface_count
    array  :surfaces, :type => :stupid_string, :initial_length => :surface_count
    uint16 :visibility_count
    array  :visibilitys, :type => :stupid_string, :initial_length => :visibility_count
    uint32 :show_alarms

    uint16 :log_count
    uint16 :class_index
    uint16 :log_version
    uint16 :log_name_size
    string :log_name, :read_length => 9

    array :dives, :initial_length => :log_count do
      choice :class_index_bis, :selection => lambda { index>0 }, :choices => { true => :uint16, false => [:array, {:type => :uint8, :initial_length=>0}] }
      uint32 :smart_type_dive
      uint32 :smart_subtype_dive
      uint32 :smart_id_dive
      uint32 :total_size
      uint32 :immersion
      uint32 :prev_dive
      int32  :utc_difference
      uint8  :repetitive
      uint8  :battery_level
      uint16 :air_temperature
      uint8  :ascent_speed
      uint16 :dive_time_limit
      uint32 :feature_set_dive
      uint16 :warnings
      uint8  :mb_level
      uint16 :max_depth
      uint16 :dive_time
      uint16 :min_temp
      uint16 :o2_mix
      uint16 :interval
      uint16 :cns_o2_after
      uint16 :tank_pressure_st
      uint16 :tank_pressure_en
      uint16 :altitude_class
      uint16 :ppo2_limit
      uint16 :depth_limit
      uint16 :tank_warning
      uint16 :tank_reserve
      uint16 :work_sensitivity
      uint16 :deco_temperature
      uint16 :desat_before
      uint16 :nofly_before
      array  :interval_detail, :type => :uint16, :initial_length => 3
      uint32 :dive_settings
      array  :internal, :type => :uint32, :initial_length => 10
      uint8  :safety_stop_timer
      uint16 :reserved
      uint16 :o2_mix_tank2
      uint16 :o2_mix_tankd
      uint16 :tank_pressure_st_tank2
      uint16 :tank_pressure_en_tank2
      uint16 :tank_pressure_st_tankd
      uint16 :tank_pressure_en_tankd
      uint16 :ppo2_limit_tank2
      uint16 :ppo2_limit_tankd
      uint16 :ppo2_user_tank1
      uint16 :ppo2_user_tank2
      uint16 :ppo2_user_tankd
      uint16 :pairing_addr_tank1
      uint16 :pairing_addr_tank2
      uint16 :pairing_addr_tankd
      uint8  :final_mb_level
      uint16 :average_depth
      uint16 :max_temp
      uint8  :avg_heart_rate
      uint8  :max_heart_rate
      uint8  :min_heart_rate
      uint8  :set_max_heart_rate
      uint8  :base_heart_rate
      uint32 :dive_settings2
      uint32 :transfer_bias
      uint32 :transfer_bias2
      uint32 :pda_immersion_null
      double :pda_immersion

      uint32  :profile_size
      array   :profile, :type => :uint8, :initial_length => :profile_size

      stupid_string :location
      stupid_string :spot
      stupid_string :position
      uint32 :tank_volume
      stupid_string :tank_type
      stupid_string :suit
      uint32 :weight
      stupid_string :weather
      stupid_string :surface
      stupid_string :water
      stupid_string :visibility
      uint16 :visibility_numeric
      uint16 :buddy_count
      array  :buddies, :type => :stupid_string, :initial_length => :buddy_count
      uint16 :equipment_count
      array  :equipments, :type => :stupid_string, :initial_length => :equipment_count
      stupid_string :notes

      uint32 :volume_tank2
      uint32 :volume_tankd
      stupid_string :type_tank2
      stupid_string :type_tankd

      uint16 :marker_count
      array :markers, :initial_length => :marker_count do
        uint16 :marker_class_index
        choice :marker_class, :selection => lambda { marker_class_index==0xffff }, :choices => {
          true => [:array, {:type => :uint8, :initial_length=>11}],
          false => [:array, {:type => :uint8, :initial_length=>0}]
        }
        uint32 :marker_index
        stupid_string :marker_string
      end
    end
  end


  def from_ASD(original_content)

    def signed_of(value,nbits)
      if value & (0x01 << (nbits-1)) != 0 then
        mask = (0x1 << nbits)-1
        return (((~value) & mask) + 1) * -1
      else
        return value
      end
    end


    #uncomment for debugging
    #data = nil
    #BinData::trace_reading do
    data = ASDFile.read(original_content)
    #end

    @dives = []
    data['dives'].each_with_index do |dive, idx|
      h = {}
      h['dive_number_in_export'] = idx
      h['beginning'] = Time.utc(1899,12,30,0,0,0) + dive['pda_immersion']*24.0*3600
      h['duration'] = dive['dive_time'] * 60.0
      h['maximum_depth'] = (dive['max_depth']/100.0).to_f
      h['reach_surface'] = h['beginning'] + h['duration']
      h['min_water_temp'] = (dive['min_temp']/10.0).to_f
      h['max_water_temp'] = (dive['max_temp']/10.0).to_f
      #h['air_temperature'] = dive['air_temperature']
      h['dive_comments'] = dive['notes'].to_s.force_encoding("iso-8859-1").encode("utf-8")
      h['site'] = dive['spot'].to_s.force_encoding("iso-8859-1").encode("utf-8")
      h['place'] = dive['location'].to_s.force_encoding("iso-8859-1").encode("utf-8")
      h['tanks'] = []
      h["buddies"] = nil
      h["guide"] = nil


      dti_table = nil
      alarm_map = []
      case dive['smart_type_dive'].to_i
        #Smart PRO
        when 0x10
          dti_table = {
            0 => {:kind => :delta_depth,          :extra_bytes => 0},
            1 => {:kind => :delta_temp,           :extra_bytes => 0},
            2 => {:kind => :time,                 :extra_bytes => 0},
            3 => {:kind => :alarms,               :extra_bytes => 0},
            4 => {:kind => :delta_depth,          :extra_bytes => 1},
            5 => {:kind => :delta_temp,           :extra_bytes => 1},
            6 => {:kind => :abs_depth,            :extra_bytes => 2},
            7 => {:kind => :abs_temp,             :extra_bytes => 2}
          }
        #Aladin TEC, TEC2
        when 0x12, 0x13
          dti_table = {
            0 => {:kind => :delta_depth,          :extra_bytes => 0},
            1 => {:kind => :delta_temp,           :extra_bytes => 0},
            2 => {:kind => :time,                 :extra_bytes => 0},
            3 => {:kind => :alarms,               :extra_bytes => 0},
            4 => {:kind => :delta_depth,          :extra_bytes => 1},
            5 => {:kind => :delta_temp,           :extra_bytes => 1},
            6 => {:kind => :abs_depth,            :extra_bytes => 2},
            7 => {:kind => :abs_temp,             :extra_bytes => 2},
            8 => {:kind => :alarms,               :extra_bytes => 1}
          }
        #Smart TEC, Smart Z
        when 0x18, 0x1c
          dti_table = {
            0 => {:kind => :delta_pressure_depth, :extra_bytes => 1},
            1 => {:kind => :delta_rbt,            :extra_bytes => 0},
            2 => {:kind => :delta_temp,           :extra_bytes => 0},
            3 => {:kind => :delta_pressure,       :extra_bytes => 1},
            4 => {:kind => :delta_depth,          :extra_bytes => 1},
            5 => {:kind => :delta_temp,           :extra_bytes => 1},
            6 => {:kind => :alarms,               :extra_bytes => 1},
            7 => {:kind => :time,                 :extra_bytes => 1},
            8 => {:kind => :abs_depth,            :extra_bytes => 2},
            9 => {:kind => :abs_temp,             :extra_bytes => 2},
            10 => {:kind => :abs_pressure,        :extra_bytes => 2},
            11 => {:kind => :abs_pressure_2,      :extra_bytes => 2},
            12 => {:kind => :abs_pressure_d,      :extra_bytes => 2},
            13 => {:kind => :abs_rbt,             :extra_bytes => 1}
          }
        #Smart COM
        when 0x14
          dti_table = {
            0 => {:kind => :delta_pressure_depth, :extra_bytes => 1},
            1 => {:kind => :delta_rbt,            :extra_bytes => 0},
            2 => {:kind => :delta_temp,           :extra_bytes => 0},
            3 => {:kind => :delta_pressure,       :extra_bytes => 1},
            4 => {:kind => :delta_depth,          :extra_bytes => 1},
            5 => {:kind => :delta_temp,           :extra_bytes => 1},
            6 => {:kind => :alarms,               :extra_bytes => 1},
            7 => {:kind => :time,                 :extra_bytes => 1},
            8 => {:kind => :abs_depth,            :extra_bytes => 2},
            9 => {:kind => :abs_pressure,         :extra_bytes => 2},
            10 => {:kind => :abs_temp,            :extra_bytes => 2},
            11 => {:kind => :abs_rbt,             :extra_bytes => 1}
          }
        #Galileo, galileo trimix
        when 0x11, 0x19
          dti_table = {
            0 => {:kind => :delta_depth,          :extra_bytes => 0},
            1 => [
                {:mask => 0xe0, :value => 0x80, :kind => :delta_rbt,       :extra_bytes => 0},
                {:mask => 0xf0, :value => 0xa0, :kind => :delta_pressure,  :extra_bytes => 0},
                {:mask => 0xf0, :value => 0xb0, :kind => :delta_temp,      :extra_bytes => 0}
              ],
            2 => [
                {:mask => 0xf0, :value => 0xc0, :kind => :time,            :extra_bytes => 0},
                {:mask => 0xf0, :value => 0xd0, :kind => :delta_heartrate, :extra_bytes => 0}
              ],
            3 => {:kind => :alarms,               :extra_bytes => 0},
            4 => [
                {:mask => 0xff, :value => 0xf0, :kind => :alarms,          :extra_bytes => 1},
                {:mask => 0xff, :value => 0xf1, :kind => :abs_depth,       :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf2, :kind => :abs_rbt,         :extra_bytes => 1},
                {:mask => 0xff, :value => 0xf3, :kind => :abs_temp,        :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf4, :kind => :abs_pressure,    :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf5, :kind => :abs_pressure,    :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf6, :kind => :abs_pressure,    :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf7, :kind => :abs_heartrate,   :extra_bytes => 1}
              ],
            5 => [
                {:mask => 0xff, :value => 0xf8, :kind => :bearing,         :extra_bytes => 2},
                {:mask => 0xff, :value => 0xf9, :kind => :alarms,          :extra_bytes => 1},
                {:mask => 0xff, :value => 0xfa, :kind => :unkown1,         :extra_bytes => 8},
                {:mask => 0xff, :value => 0xfb, :kind => :unkown2,         :extra_bytes => 1, :extra_variable => true}
              ]
          }
        else nil
      end


      h['sample'] = []
      profile = dive['profile'].to_ary
      time = 0
      pressure = 0
      depth = 0
      temperature = 0
      heartrate = 0
      complete = 0
      depth_calibration = nil
      sample_data = {
            "main_cylinder_pressure" => nil,
            "current_water_temperature" => nil,
            "heart_beats" => nil,
            "ascent_violation" => "F",
            "deco_violation" => "F",
            "deco_start" => "F",
            "bookmark" => "F",
            "surface_event" => "F",
            "gas_switch" => "1.0"
          }
      while dti_table && byte = profile.shift do
        # Hey, what's that shit
        zero_position = 0
        while byte & (0x80>>(zero_position%8)) != 0  do
          zero_position += 1
          byte = profile.shift if zero_position%8 == 0
        end
        byte_value = byte & (0xff >> (zero_position % 8))

        # Now we know what we're talking about
        sample_specs = dti_table[zero_position]

        # For galileo, it's a bit more complicated
        if sample_specs.is_a? Array then
          found_spec = nil
          sample_specs.each do |spec|
            found_spec = spec if (byte & spec[:mask]) == spec[:value]
          end
          raise DBArgumentError.new "Invalid format for galileo profile" unless found_spec
          sample_specs = found_spec
          byte_value &= ~found_spec[:mask]
        end

        # Getting the extra bytes
        extra_data_bytes = []
        total_value = byte_value
        sample_specs[:extra_bytes].times do
          extra_byte = profile.shift
          extra_data_bytes.push extra_byte
          total_value = total_value * 256 + extra_byte
        end

        # For galileo unknown2
        extra_variable = []
        if sample_specs[:extra_variable] then
          total_value.times do
            extra_variable.push profile.shift
          end
        end

        # Divers sometimes come back to surface : delta values can be negative....
        nbits = sample_specs[:extra_bytes]*8 + 8 - (zero_position%8) - 1
        signed_total_value = signed_of total_value, nbits

        case sample_specs[:kind]
          when :delta_pressure_depth then
            pressure += (signed_of(byte_value, 8 - (zero_position%8) - 1) / 4.0).to_f
            depth += (signed_of(extra_data_bytes[0],8) / 50.0).to_f
            sample_data['main_cylinder_pressure'] = pressure
            complete = 1
          when :delta_pressure then
            pressure += (signed_total_value / 4.0).to_f
            sample_data['main_cylinder_pressure'] = pressure
          when :delta_depth
            depth += (signed_total_value / 50.0).to_f
            complete = 1
          when :delta_temp then
            temperature += (signed_total_value / 2.5).to_f
            sample_data['current_water_temperature'] = temperature
          when :abs_depth then
            depth = (total_value / 50.0).to_f
            depth_calibration ||= depth
            depth = depth - depth_calibration
            complete = 1
          when :abs_temp then
            temperature = (total_value / 2.5).to_f
            sample_data['current_water_temperature'] = temperature
          when :abs_pressure then
            pressure = (total_value / 4.0).to_f
            sample_data['main_cylinder_pressure'] = pressure
          when :delta_heartrate then
            heartrate = signed_total_value
            sample_data['heart_beats'] = heartrate
          when :abs_heartrate then
            heartrate = total_value
            sample_data['heart_beats'] = heartrate
          when :time then
            complete = total_value
          when :alarms, :delta_rbt, :abs_rbt, :abs_pressure_2, :abs_pressure_d, :bearing then
            nil
        end

        depth = 0 if depth < 0

        complete.times do
          sample_data['time'] = time
          sample_data['depth'] = depth
          h['sample'].push sample_data

          time += 4
          sample_data = {
            "main_cylinder_pressure" => nil,
            "current_water_temperature" => nil,
            "heart_beats" => nil,
            "ascent_violation" => "F",
            "deco_violation" => "F",
            "deco_start" => "F",
            "bookmark" => "F",
            "surface_event" => "F",
            "gas_switch" => "1.0"
          }
          complete = 0
        end

      end
      @dives.push h
    end

    return nil
  end



  #TODO: use standard ruby name format
  def fromDiveDB(dive_numbers)

    @dives = []

    if !dive_numbers.kind_of?(Array) && !dive_numbers.kind_of?(Range) then
      dive_numbers = [ dive_numbers ]
    end

    dive_numbers.each{ |dive_id|
      dive = Dive.fromshake(dive_id)

      if dive.nil? then next end
      if dive.id == 1 then next end

      dive_h = {}

      dive_h["internal_sequence"] = dive_id
      dive_h["beginning"] = dive.time_in
      dive_h["maximum_depth"] = dive.maxdepth.to_f
      dive_h["duration"] = dive.duration.to_f*60
      dive_h["reach_surface"] = dive.time_in + dive.duration.to_i
      dive_h["min_water_temp"] = dive.temp_bottom
      dive_h["max_water_temp"] = dive.temp_surface
      dive_h["air_temperature"] = ""                              #TODO: differentiate air temp and max temp
      dive_h["safetystops"] = dive.safetystops
      dive_h["dive_comments"] = dive.notes
      dive_h["buddies"] = dive.legacy_buddies_hash
      if dive.uploaded_profile.nil? || dive.uploaded_profile.source != 'computer' then
        dive_h["mode"] = "M"
      else
        dive_h["mode"] = "I"
      end
      dive_h["sample"] = []
      if dive.spot_id == 1
        dive_h["location"] = "UnknownPlace, Unknown Location, Unknown Country"
      else
        dive_h["location"] = "#{dive.spot.name}, #{dive.spot.location.name}, #{dive.spot.country.cname}"
      end
      ## TODO : add diver name, add dive location

      dive_h["tanks"] = []
      dive.tanks.each do |tank|
        if tank.gas == 'custom'
          o2 = tank.o2
          n2 = tank.n2
          he = tank.he
        elsif tank.gas == 'EANx32' then
          o2 = 32
          n2 = 68
          he = 0
        elsif tank.gas == 'EANx36' then
          o2 = 36
          n2 = 64
          he = 0
        elsif tank.gas == 'EANx40' then
          o2 = 40
          n2 = 60
          he = 0
        elsif tank.gas == 'air' then
          o2 = 21
          n2 = 79
          he = 0
        end

        dive_h['tanks'].push({
          'material' => tank.material,
          'volume' => tank.volume,
          'multitank' => tank.multitank,
          'o2' => o2,
          'n2' => n2,
          'he' => he,
          'p_start' => tank.p_start,
          'p_end' => tank.p_end,
          'time_start' => tank.time_start
        })
      end

      if ProfileData.where(:dive_id => dive.id).where("depth is not null").count > 0 then
        Media.select_all_sanitized("select * from profile_data where dive_id = :dive_id", :dive_id => dive.id).each do |data|
          if data['seconds'] > dive["duration"] then
            dive["duration"] = data['seconds']
          end

          sample = {}
          sample["time"] = data['seconds']
          sample["ascent_violation"] = "F"
          sample["deco_violation"] = "F"
          sample["deco_start"] = "F"
          sample["bookmark"] = "F"
          sample["surface_event"] = "F"
          sample["heart_beats"] = ""
          sample["main_cylinder_pressure"] = nil
          sample["gas_switch"] = "1.0"

          sample["depth"] = data['depth'] unless data['depth'].nil?
          sample["current_water_temperature"] = data['current_water_temperature'] unless data['current_water_temperature'].nil?
          sample["main_cylinder_pressure"] = data['main_cylinder_pressure'] unless data['main_cylinder_pressure'].nil?
          sample["heart_beats"] = data['heart_beats'] unless data['heart_beats'].nil?

          sample["ascent_violation"] = "T" if data['ascent_violation'] > 0
          sample["deco_violation"] = "T" if data['deco_violation'] > 0
          sample["deco_start"] = "T" if data['deco_start'] > 0
          sample["bookmark"] = "T" if data['bookmark'] > 0
          sample["surface_event"] = "T" if data['surface_event'] > 0

          dive_h["sample"].push(sample)
        end
      else
        generate_dummy_profile(dive_h)
      end

      @dives.push dive_h
    }
  end

  def toDiveDB(dive_number, dive)

    if dive.nil? || dive.id.nil? then
      return
    end

    if !@dives[dive_number]["dive_comments"].nil? then
      dive.notes = @dives[dive_number]["dive_comments"]
    end

    Rails.logger.debug "Dive to update : #{dive.spot_id} #{dive.spot}"

    if dive.spot_id==1 || dive.spot.nil? then

      site = @dives[dive_number]["site"] && @dives[dive_number]["site"].gsub(/^ */, '').gsub(/ *$/,'')
      place = @dives[dive_number]["place"] && @dives[dive_number]["place"].gsub(/^ */, '').gsub(/ *$/,'')

      Rails.logger.debug "Searching spot for : site='#{site}' place='#{place}'"

      if !site.nil? then
        s = Spot.find_or_create_by_name(site, place, dive.user_id)

        Rails.logger.debug "Linking dive to site '#{s.name}' (#{s.id})"
        dive.spot_id = s.id
        dive.save
      end

    end

    if dive.tanks.blank? && !@dives[dive_number]['tanks'].blank? then
      @dives[dive_number]['tanks'].each do |th|
        tank = Tank.new
        tank.material = th['material']
        tank.volume = th['volume']
        tank.multitank = th['multitank']
        tank.gas = 'custom'
        tank.o2 = th['o2']
        tank.n2 = th['n2']
        tank.he = th['he']
        tank.p_start = th['p_start']
        tank.p_end = th['p_end']
        tank.time_start = th['time_start']
        tank.dive_id = dive.id
        tank.save
      end
    end

    dive.raw_profile.map &:delete

    profiles_data = []
    @dives[dive_number]["sample"].each { |sample|
      rec = {:main_cylinder_pressure => nil, :heart_beats => nil}
      rec[:dive_id] = dive.id
      rec[:seconds] = sample["time"].to_i
      rec[:depth] = sample["depth"]
      rec[:current_water_temperature] = sample["current_water_temperature"]
      rec[:deco_violation] = sample["deco_violation"] == "T"
      rec[:deco_start] = sample["deco_start"] == "T"
      rec[:ascent_violation] = sample["ascent_violation"] == "T"
      rec[:bookmark] = sample["bookmark"] == "T"
      rec[:surface_event] = sample["surface_event"] == "T"
      rec[:heart_beats] = sample["heart_beats"].to_f if sample["heart_beats"].to_f > 0
      rec[:main_cylinder_pressure] = sample["main_cylinder_pressure"].to_f if sample["main_cylinder_pressure"].to_f > 0
      profiles_data.push rec
    }
    Media.insert_bulk_sanitized 'profile_data', profiles_data

  end

  def generate_dummy_profile(dive_h)

    duration = dive_h["duration"]
    max_depth = dive_h["maximum_depth"]
    stops = []
    stops = JSON.parse(dive_h["safetystops"]) if !dive_h["safetystops"].nil?
    total_stop_time = 0

    if duration <= 0 then
      return
    end

    stops.each do |depth, time|
      total_stop_time += time.to_f
    end

    # if the stop time exceed the dive time, it's not normal ! let's just discard the stop informations...
    if total_stop_time + max_depth/15 + max_depth/20 > duration/60 then
      stops = []
      total_stop_time = 0
    end

    profile = []
    dive_h["sample"] = profile

    sample_t = {}
    sample_t["ascent_violation"] = "F"
    sample_t["deco_violation"] = "F"
    sample_t["deco_start"] = "F"
    sample_t["bookmark"] = "F"
    sample_t["surface_event"] = "F"
    sample_t["gas_switch"] = "1.0"

    sample = sample_t.clone
    sample["time"] = 0
    sample["depth"] = 0
    profile.push sample

    # if there's not even enough time to go down and come back safely,
    #then let's assume the user is dead and the last thing he'll complain about is to have a square dive profile
    if (60 * max_depth / 20).round + (60 * max_depth / 15).round > duration then
      sample = sample_t.clone
      sample["time"] = (duration/10).to_i
      sample["depth"] = max_depth
      profile.push sample

      sample = sample_t.clone
      sample["time"] = (9*duration/10).to_i
      sample["depth"] = max_depth
      profile.push sample

      sample = sample_t.clone
      sample["time"] = duration
      sample["depth"] = 0
      profile.push sample

      return
    end

    sample = sample_t.clone
    sample["time"] = (60 * max_depth / 20).round
    sample["depth"] = max_depth
    profile.push sample

    sample = sample_t.clone
    sample["time"] = (duration - 60*total_stop_time - 60*max_depth/15).round
    sample["depth"] = max_depth
    profile.push sample

    remaining_stop_time = total_stop_time
    stops.sort{|a,b| b[0].to_f <=> a[0].to_f}.each do |depth_s, time_s|
      depth = depth_s.to_f
      time = time_s.to_f
      sample = sample_t.clone
      sample["time"] = (duration - 60*remaining_stop_time - 60*depth/15).round
      sample["depth"] = depth
      profile.push sample

      remaining_stop_time -= time

      sample = sample_t.clone
      sample["time"] = (duration - 60*remaining_stop_time - 60*depth/15).round
      sample["depth"] = depth
      profile.push sample
    end

    sample = sample_t.clone
    sample["time"] = duration.round
    sample["depth"] = 0
    profile.push sample


  end

end
