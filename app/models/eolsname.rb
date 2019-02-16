require 'delayed_job'

class Eolsname < ActiveRecord::Base
  has_many :eolcnames
  has_and_belongs_to_many :dives,
                          :class_name => 'Dive',
                          :join_table => "dives_eolcnames",
                          :foreign_key => 'sname_id',
                          :association_foreign_key => 'dive_id',
                          :uniq => true

  has_and_belongs_to_many :pictures,
                          :join_table => 'pictures_eolcnames',
                          :association_foreign_key => 'picture_id',
                          :foreign_key => 'sname_id',
                          :uniq => true


  has_many :fish_frequencies, :foreign_key => 'gbif_id', :primary_key => 'gbif_id'

  before_create :eol_description, :thumbnail_href


  def to_hash
    hash = {}
    hash[:id] = "s-"+self.id.to_s
    hash[:sname] = self.sname
    hash[:cname] = self.preferred_cname
    hash[:picture] = self.picture_href
    hash[:url] = self.url
    hash[:description]=self.eol_description
    return hash
  end

  def self.hierarchy
    ##the book of life - in a tree
    return {'life' => 0, 'domain' => 1, 'kingdom' => 2, 'phylum' => 3, 'class' => 4, 'order' => 5, 'family' => 6, 'genus' => 7, 'species' => 8}
  end

  def url
    "http://www.eol.org/pages/#{self.id}"
  end

  def self.import_from_eol id
    ##grabs EOL data from one single species
    raise DBArgumentError.new "ill-formatted id", id: id if id.class != Fixnum
    if Eolsname.find_by_id(id).nil?
      Rails.logger.debug "entry with EOL id #{id} is missing"
      dataurl = "http://eol.org/api/pages/1.0/#{id}.json?images=30&common_names=1&details=1"
      line = Net::HTTP.get URI.parse(dataurl)

      if line.match(/^\</).nil? && line.match(/^\{/).nil? then
        raise DBArgumentError.new "EOL response does not start with < or { - maybe id is wrong"
      end
      #if line.match(/worms/i).nil? && line.match(/fishbase/i).nil? then
      #  raise "no worms or fishbase record, this is not a marine species"
      #end
      json = JSON.parse(line)

      picture = 0
      if !json["dataObjects"].nil?
        json["dataObjects"].each do |dataset|
          picture = picture+1
          if dataset.to_s.match(/MediaURL/i)
            break  ## we found one image
          end
        end
      end
      worms_id = nil
      fishbase_id = nil
      if !json["taxonConcepts"].nil?
        json["taxonConcepts"].each do |entry|
          if entry["nameAccordingTo"].match(/WORMS/i)
            worms_id = entry["identifier"].to_i
          elsif entry["nameAccordingTo"].match(/FishBase/i)
            fishbase_id = entry["identifier"].to_i
          end
        end
      end


      if !json["identifier"].nil?
        Rails.logger.debug "Creating new species #{json["identifier"]} from EOL"
        new_entry = Eolsname.new do |e|
          e.id = json["identifier"].to_i
          e.sname = json["scientificName"]
          e.taxon = json["taxonConcepts"].to_json
          e.data = json["dataObjects"].to_json
          e.picture = picture
          e.worms_id = worms_id
          e.fishbase_id = fishbase_id
        end
        new_entry.save

        if !json["vernacularNames"].nil?
          Rails.logger.debug "adding #{json["vernacularNames"].count} Cnames records"
          json["vernacularNames"].each do |cname|
            if cname["eol_preferred"].nil?
              preferred= false
            else
              preferred= true
            end

            new_cname = Eolcname.new do |e|
              e.eolsname_id = new_entry.id
              e.cname = cname["vernacularName"]
              e.language = cname["language"]
              e.eol_preferred = preferred
            end
            new_cname.save
          end
        end
        new_entry.reload
        new_entry.update_hierarchy
        new_entry.reload
        new_entry.update_taxonrank
        new_entry.reload
        new_entry.update_parent
      else
        raise DBTechnicalError.new "No usable data"
      end
    else
       Rails.logger.debug "entry with EOL id #{id} is present, skippign creation"
    end
    ##now let's check all the children and ancestors exist
  end

  def finalize_species_addition
    begin
      Rails.logger.debug "Checkign missing family"
      self.check_missing_family
      ##reindex
      self.taxonrank = "unclassified" if self.taxonrank.nil? ## fix for missing EOL classification - that way it will show up in results
      self.save
      Rails.logger.debug "Reindexing"
      raise DBArgumentError.new "Indexer failes on eolsnames tables" unless system( "/usr/bin/indexer --rotate --config #{Rails.root}/config/#{Rails.env}.sphinx.conf eolcname_core eolsname_core > /dev/null 2>&1")
    rescue
      Rails.logger.debug "Error while finalizing species addition from species ##{self.id}"
      NotificationHelper.mail_background_exception $!, "Error while finalizing species addition from species ##{self.id}"
    end
  end
  handle_asynchronously :finalize_species_addition


  def check_missing_family
    ##looks for missing ancestors or children

    hierarchy = {'life' => 0, 'domain' => 1, 'kingdom' => 2, 'phylum' => 3, 'class' => 4, 'order' => 5, 'family' => 6, 'genus' => 7, 'species' => 8}

    begin
      taxonid = JSON.parse(self.taxon)[0]["identifier"]
      dataurl = "http://eol.org/api/hierarchy_entries/1.0/#{taxonid}.json"
      line = Net::HTTP.get URI.parse(dataurl)

      if line.match(/^\</).nil? && line.match(/^\{/).nil? then
        raise DBArgumentError.new "EOL response does not start with < or { - maybe id is wrong"
      end
      #if line.match(/worms/i).nil? && line.match(/fishbase/i).nil? then
      #  raise "no worms or fishbase record, this is not a marine species"
      #end
      json = JSON.parse(line)
      ancestors = json["ancestors"].map{|e|e["taxonConceptID"]}
      children = json["children"].map{|e|e["taxonConceptID"]}
      current_rank  = json["taxonRank"]
      daddy_taxonid = json["ancestors"].last["taxonID"]

      Rails.logger.debug
      dataurl = "http://eol.org/api/hierarchy_entries/1.0/#{daddy_taxonid}.json"
      line = Net::HTTP.get URI.parse(dataurl)

      if line.match(/^\</).nil? && line.match(/^\{/).nil? then
        raise DBArgumentError.new "EOL response does not start with < or { - maybe id is wrong"
      end
      #if line.match(/worms/i).nil? && line.match(/fishbase/i).nil? then
      #  raise "no worms or fishbase record, this is not a marine species"
      #end
      json = JSON.parse(line)
      ancestors = json["ancestors"].map{|e|e["taxonConceptID"]}
      children = json["children"].map{|e|e["taxonConceptID"]}
      family = ancestors+children + [json["taxonConceptID"]]
      Rails.logger.debug "Checking family members #{family.to_s}"
      family.each do |family_member_id|
        Eolsname.import_from_eol family_member_id
      end
      family.each do |family_member_id|
        e = Eolsname.find(family_member_id)
        if e.category.nil?
          e.category = e.lookup_category
          e.save
        end
      end

    rescue
      Rails.logger.debug $!.message
    end
  end

  def picture_href
    thumbnail_href ##dunno why we have a dupe
  end

  def thumbnail_href
    #enforcing an https response
    return thumbnail_href_http.gsub(/^http\:/, "https:")
  end
    
  def thumbnail_href_http
    thurl = read_attribute(:thumbnail_href)
    return thurl unless thurl.nil?
    if self.picture != 0
      #we've got a picture
      jdata = JSON.parse(self.data)
      jdata.each do |media|
        if !media["eolThumbnailURL"].nil?
          thurl = media["eolThumbnailURL"].gsub(/\/\/content[0-9]*\./, "//")
          self.thumbnail_href = thurl
          return thurl
        end
      end
      begin
        thurl = jdata[self.picture-1]["MediaURL"].gsub(/\/\/content[0-9]*\./, "//")
        self.thumbnail_href = thurl
        return thurl
      rescue
        self.thumbnail_href = ""
        return ""
      end
    else
      self.thumbnail_href = ""
      return ""
    end
  end
  def thumbnail_href=(val)
    write_attribute(:thumbnail_href, val)
  end

  def eol_pictures
    ## extracts all pictures from data
    begin
      info = JSON.parse(data)
      pics =[]
      info.each do |e|
        if !e["eolMediaURL"].nil?
          pics.push e["eolMediaURL"]
        elsif !media["eolThumbnailURL"].nil?
          pics.push media["eolThumbnailURL"]
        elsif !e["mediaURL"].nil?
            pics.push e["mediaURL"]
        end
      end
      return pics
    rescue
      return [thumbnail_href]
    end
  end

  def self.get_cname_data(ids)
    return {} if ids.blank?
    connection.execute "SET SESSION group_concat_max_len = 50000"
    cname_data = connection.select_all "SELECT eolsname_id id,
      GROUP_CONCAT(c.cname SEPARATOR '|-|') array_cnames,
      SUBSTR(MIN( CASE WHEN c.eol_preferred = 1 and c.language = 'en' then CONCAT('0 ', c.cname)
        WHEN c.eol_preferred = 1 then CONCAT('1 ', c.cname)
        WHEN c.language = 'en' then CONCAT('2 ', c.cname)
        ELSE CONCAT('3 ', c.cname)
        END), 3) preferred_cname
      FROM eolcnames c
      WHERE c.eolsname_id IN (#{ids.join ','})
      GROUP BY eolsname_id"
    results = {}
    cname_data.each do |cname|
      cname['array_cnames'] = cname['array_cnames'].split('|-|') rescue []
      cname['preferred_cname'] = '' if cname['preferred_cname'].nil?
      results[cname['id']] = cname
    end
    ids.each do |id|
      results[id] ||= {'array_cnames' => [], 'preferred_cname' => ''}
    end
    return results
  end

  def get_cname_data
    if @cname_data.nil? then
      connection.execute "SET SESSION group_concat_max_len = 50000"
      @cname_data = connection.select_one "SELECT GROUP_CONCAT(c.cname SEPARATOR '|-|') array_cnames,
        SUBSTR(MIN( CASE WHEN c.eol_preferred = 1 and c.language = 'en' then CONCAT('0 ', c.cname)
          WHEN c.eol_preferred = 1 then CONCAT('1 ', c.cname)
          WHEN c.language = 'en' then CONCAT('2 ', c.cname)
          ELSE CONCAT('3 ', c.cname)
          END), 3) preferred_cname
        FROM eolcnames c
        WHERE c.eolsname_id = #{self.id}"
      @cname_data['array_cnames'] = @cname_data['array_cnames'].split('|-|') rescue []
      @cname_data['preferred_cname'] = '' if @cname_data['preferred_cname'].nil?
    end
    @cname_data
  end

  def array_cnames
    get_cname_data['array_cnames']
  end

  def preferred_cname
    get_cname_data['preferred_cname']
  end

  def update_taxonrank
    #updated the "global" taxonrank - check worms first, if nothing fishbase
    if !worms_taxonrank.nil?
      self.taxonrank = worms_taxonrank
    elsif fishbase_taxonrank.nil?
      self.taxonrank = fishbase_taxonrank
    else
      self.taxonrank =  "unclassified"
    end
    self.save
  end

  def update_parent
    #returns the paren - check worms first, if nothing fishbase
    if !worms_parent_id.nil?
      parent = Eolsname.find_by_worms_id(worms_parent_id)
      if !parent.blank?
        self.parent_id = parent.id
      end
    elsif !fishbase_parent_id.nil?
      parent = Eolsname.find_by_fishbase_id(fishbase_parent_id)
      if !parent.blank?
        self.parent_id = parent.id
      end
    else
      self.parent_id=nil
    end
   self.save
  end

  def all_parents
    list = []
    if parent.nil?
      list.push self
    else
      list.push self
      parent.all_parents.each {|p| list.push p}
    end
    return list

  end


  def frequency
    if self.gbif_id.nil? then
      return nil
    end

    if self.fish_frequencies.count == 0 then
      self.update_frequencies
    end

    return self.fish_frequencies.sum(:count)

  end

  def frequencies

    if self.gbif_id.nil? then
      return nil
    end

    if self.fish_frequencies.count == 0 then
      self.update_frequencies
    end

    return self.fish_frequencies
  end


  def update_frequencies

    start_index = 0
    continue_request = true
    map = {}

    while continue_request do

      url = "http://data.gbif.org/ws/rest/occurrence/list?startindex=#{start_index}&coordinatestatus=true&taxonconceptkey="
      url += self.gbif_id.to_s

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

        if map[this_lat.to_i].nil?  then map[this_lat.to_i] = {} end
        if map[this_lat.to_i][this_lng.to_i].nil? then
          map[this_lat.to_i][this_lng.to_i] = 1
        else
          map[this_lat.to_i][this_lng.to_i] += 1
        end
      }
    end

    FishFrequency.where(:gbif_id => self.gbif_id).map(&:delete)

    map.each{ |lat,map_lng|
      map_lng.each{ |lng,count|
        frequency = FishFrequency.new
        frequency.gbif_id = self.gbif_id
        frequency.lat = lat
        frequency.lng = lng
        frequency.count = count
        frequency.save
      }
    }

    return nil

  end

  def self.most_common(lat, lng)
    most_common_gbif = FishFrequency.where(:lat => lat, :lng => lng).order('count desc').limit(10)
    most_common_gbif.map(&:eolsnames).flatten
  end

  def self.most_common_in_area(lat1, lng1, lat2, lng2)
    lats = (lat1.to_i..lat2.to_i).map(&:to_i)
    if lng1 <= lng2 then
      lngs = (lng1.to_i..lng2.to_i).map(&:to_i)
    else
      lngs = (lng1.to_i..180).map(&:to_i) + (-180..lng2.to_i).map(&:to_i)
    end
    most_common_gbif = FishFrequency.where('lat in (:lats) AND lng in (:lngs)', :lats => lats, :lngs => lngs).group(:gbif_id).order('sum(count) desc').limit(10)
    most_common_gbif.map(&:eolsnames).flatten
  end

  def update_hierarchy
    ## Will update hierarchy data from EOL based on hierarchy index by worms and fishbase
    require 'net/http'
    require 'uri'

    def next_rank rank
      order = ['life', 'domain', 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species'].to_enum
      order.rewind
      begin

      end while order.next != rank
      return order.next
    end


    if !self.worms_id.nil?
      begin
        rawdata = Net::HTTP.get URI.parse("http://eol.org/api/hierarchy_entries/1.0/#{self.worms_id}.json")
        data= JSON.parse(rawdata)
        if data.class != Hash then raise DBArgumentError.new "EOL data should be a Hash" end
        ##there is WORMS DATA
        self.worms_parent_id = data["parentNameUsageID"]
        self.worms_hierarchy = rawdata
        data["ancestors"].each do |ancestors|
          if ancestors["taxonID"] == data["parentNameUsageID"]
            self.worms_taxonrank = next_rank ancestors["taxonRank"]
          end
        end
      rescue
        logger.debug "cannot get hierarchy data for id #{self.id} WORMS_ID=#{self.worms_id}"
      end
    end

    if !self.fishbase_id.nil?
       begin
         rawdata =  Net::HTTP.get URI.parse("http://eol.org/api/hierarchy_entries/1.0/#{self.fishbase_id}.json")
         data= JSON.parse(rawdata)
         if data.class != Hash then raise DBArgumentError.new "EOL data should be a Hash" end
         ##there is fishbase DATA
         self.fishbase_hierarchy = rawdata
         self.fishbase_parent_id = data["parentNameUsageID"]
         data["ancestors"].each do |ancestors|
           if ancestors["taxonID"] == data["parentNameUsageID"]
             self.fishbase_taxonrank = next_rank ancestors["taxonRank"]
           end
         end
       rescue
         logger.debug "cannot get hierarchy data for id #{self.id} FISHBASE_ID=#{self.fishbase_id}"
       end
     end
     self.save!
  end

  def is_marine?
    if self.worms_hierarchy.nil? then return false end

     class_list = {:marine =>[
                {:taxonRank => :class, :sname => "Myxini" },
                {:taxonRank => :class, :sname => "Cephalaspidomorphi"},
                {:taxonRank => :class, :sname => "Chondrichthyes"},
                {:taxonRank => :class, :sname => "Osteichthyes"},
                {:taxonRank => :phylum, :sname => "Hemichordata"},
                {:taxonRank => :phylum, :sname => "Echinoderm"},
                {:taxonRank => :order, :sname => "Cetacea"},
                {:taxonRank => :order, :sname => "Sirenia"},
                {:taxonRank => :species, :sname => "Enhydra lutris"},
                {:taxonRank => :species, :sname => "Lontra feline"},
                {:taxonRank => :species, :sname => "Ursus maritimus"},
                {:taxonRank => :family, :sname => "Otariidae"},
                {:taxonRank => :family, :sname => "Odobenidae"},
                {:taxonRank => :family, :sname => "Phocidae"},
                {:taxonRank => :class, :sname => "Bivalvia"},
                {:taxonRank => :class, :sname => "Cephalopoda"},
                {:taxonRank => :class, :sname => "Polyplacophora"},
                {:taxonRank => :class, :sname => "Scaphopoda"},
                {:taxonRank => :family, :sname => "Amphinomidae"},
                {:taxonRank => :class, :sname =>"Actinopterygii"},
                {:taxonRank => :order, :sname => "Testudines"},
                {:taxonRank => :family, :sname => "Delphinidae"}

              ],
            :corals =>[
                {:taxonRank => :class, :sname => "Anthozoa"}
              ]
      }

    JSON.parse(self.worms_hierarchy)["ancestors"].each do |ancestor|
      element = {:taxonRank => ancestor["taxonRank"].to_sym, :sname  => ancestor["scientificName"]}
      if class_list[:marine].include? element then return true end
    end

    return false
  end

  def parent
    begin return Eolsname.find(parent_id) rescue return nil end
  end

  def parents
    if !self.parent.nil?
      return [self].push(self.parent.parents).flatten
    else
      return [self]
    end
  end

  def find_ancestor_with_rank rank
    self.parents.each do |e|
      return e if e.taxonrank == rank
    end
    return nil
  end

  def children
    return Eolsname.where("parent_id = ?", self.id)
  end

  def get_children_species rank="species"
    ##returns children of a given rank
    children = []
    if taxonrank == rank then return Eolsname.find(self.id) end
    Eolsname.where("parent_id = ?", self.id).each do |child|
      if !child.get_children_species.nil?
        children << child.get_children_species
      end
    end
    return children.flatten
  end
  def get_all_children
    ##returns all descendants of all ranks
    children =[]
    children.push self
    if !self.children.empty?
      self.children.each {|c| children.push c.get_all_children}
    end
    return children.flatten
  end


  def eol_description
    description = read_attribute(:eol_description)
    return description unless description.nil?
    description=""
    begin
      JSON.parse(self.data).each do |f|
        begin
         if !f["description"].blank? && !f["title"].blank? && f["title"].downcase == "biology"
           description=f["description"]
            break
         end
       rescue
       end
     end
    rescue
    end
    desc= description.gsub(/\([a-zA-Z0-9\ \.\,]*\)/i,"")
    self.eol_description = desc
    return desc
  end

  def eol_description=(val)
    write_attribute(:eol_description, val)
  end

  def update_category category, opts={}
    #TODO will apply catagery as defined by species_groups to current species
    #if opts[:recursive] = true, all children will be tagged to category


  end


#####
#####  METHODS to regenerate the "category" column
#####
  def eolid_ancestors
    begin
      if !worms_hierarchy.blank?
        eolid_list = []
        ancestors = JSON.parse(self.worms_hierarchy)
        ancestors["ancestors"].each do |e|
          begin
            eolID = (Eolsname.find_by_worms_id e["taxonID"]).id
            eolid_list << eolID
          rescue
          end
        end
        return eolid_list
      elsif !fishbase_hierarchy.blank?
        eolid_list = []
        ancestors = JSON.parse(self.fishbase_hierarchy)
        ancestors["ancestors"].each do |e|
          begin
            eolID = (Eolsname.find_by_fishbase_id e["taxonID"]).id
            eolid_list << eolID
          rescue
          end
        end
        return eolid_list
      else
        return []
      end
    rescue
      return []
    end
  end


  def get_parrotfish rank="species"
    result=""
    Eolsname.find_by_sname("Scaridae").get_children_species(rank).each do |species|
      begin
        fr = species.fish_frequencies.where("lat>13").where("lat<24").where("lng>-87").where("lng<-75")
        count = 0
        fr.each do |f|
          count += f.count
        end
        if count >0
          result += "#{species.sname},#{count}\n"
        end
      rescue
        #result += "#{species.sname},0\n"
      end
    end
    puts result
    return result.split("\n").count
  end



  def species_groups
=begin
        HUMAN READABLE VERSION OF THE SPECIES_GROUP OBJECT
        sharks => 1857 elasmobranchii
        sharks commenseals => 5361 # carangidae : pilotfishes
              5331 # Echeneidae : remoras
              5216 # Rachycentridae: cobia
        rays => 8898 #Torpediniformes
              1864 #Pristiformes
              1858 #Rajiformes
              ##Myliobatiformes: apparently does not exist in worms class >  found in rajiformes
        Tarpon and bonefish => 23987 Megalops
              2776871 Albula BVulpes
        Eels => 8280 Anguilliformes
        Barracudas => 24821 Sphyraena
        Snook => 5355 Centropomidae
        Slim Bodied Fish  => 5192 Trichonotidae
              216494 Limnichthys polyactis
              216495 Tewara cranwellae
              17480 Synodus
              5068 Aulostomidae (trumpetfishes)
              5066 Fistulariidae (cornetfishes)
              8244 Hemiramphidae (halfbeaks)
              8246 Belonidae (needlefishes)
        Cardinalfishes => 5377 Apogonidae
        Squirrelfishes => 23827 Holocentrus
              24504 Neoniphon
              24317 Sargocentron
        Hamlets => 25212 Hypoplectrus
        Seabasses and Basslets =>
              24577 Aethaloperca +
              101429 Anatolanthias +
              24494 Anthias +
              25641 Aporops +
              26407 Aulacocephalus +
              26889 Bathyanthias +
              !!!!MISSING Batrachus +
              27161 Belonoperca +
              26464 Bullisichthys +
              25356 Caesioperca +
              26848 Caesioscorpis +
              24688 Centropristis +
              24147 Chelidoperca +
              28418 Cratinus +
              27749 Dactylanthias +
              24685 Diplectrum +
              26748 Diploprion +
              25417 Epinephelides +
              27748 Giganthias +
              27762 Glaucosoma +
              25208 Grammistes +
              28602 Grammistops +
              27436 Hemanthias +
              26361 Hemilutjanus +
              25426 Holanthias +
              25212 Hypoplectrus +
              4571002 Hyporthodus +
              26625 Jeboehlkia +
              25357 Lepidoperca +
              24757 Luzonichthys +
              4571215 Meganthias +
              26331 Nemanthias +
              25427 Odontanthias +
              25358 Othos +
              24799 Paralabrax +
              28035 Parasphyraenops +
              28401 Planctanthias +
              24681 Plectranthias +
              25207 Pogonoperca +
              26315 Pronotogrammus +
              24493 Pseudanthias +
              26465 Pseudogramma +
              26463 Rabaulichthys +
              25546 Rainfordia +
              24984 Rypticus +
              27215 Sacura +
              28273 Schultzea +
              26789 Selenanthias +
              28472 Serraniculus +
              27750 Serranocirrhitus +
              23804 Serranus +
              108840 Suttonia +
              26773 Tosana +
              28496 Tosanoides +
              26763 Trachypoma +


              204766 Lates calcarifer
              206645 Dissostichus eleginoides
              224729 Dicentrarchus labrax
              MISSING !!! Stereolepis gigas
              204582 Lateolabrax japonicus
              MISSING !!! Cynoscion nobilis
              5318 Grammatidae (basslets)
        Bigeyes => 5221 Priacanthidaev
        Groupers =>
              24039 Acanthistius +
              24689 Alphestes +
              27865 Anyperodon +
              25416 Caprodon +
              24424 Cephalopholis +
              99524 Cromileptes +
              26620 Dermatolepis +
              24209 Epinephelus +
              23843 Gonioplectrus +
              27113 Gracila +
              26375 Hypoplectrodes +
              24679 Liopropoma +
              24210 Mycteroperca +
              28230 Niphon +
              24787 Paranthias +
              26822 Plectropomus +
              26823 Saloptia +
              101681 Triso +
              23960 Variola +
        Jacks => 5361 Carangidae
        Snappers => 5294 Lutjanidae
              344840 Pagrus auratus
              206429 Centroberyx affinis
              205264 Pomatomus saltatrix
        Grunts => 5317 Haemulidae
              5127 Rhamphocottidae
        Goatfishes => 5286 Mullidae
        Porgies => 5203 Sparidae
        Drums => 5211 Sciaenidae
        Flatfish => Pleuronectiformes
        Butterflyfishes => 5352 Chaetodontidae
        Spadefish => 5324 Ephippidae
        Angelfishes => 25498 Pterophyllum
               5260 Pomacanthidae
        Damselfishes =>
              24246 Abudefduf (sergeant majors)
              26865 Acanthochromis
              28078 Altrichthys
              24247 Amblyglyphidodon
              28021 Amblypomacentrus
              27418 Azurina
              99481 Cheiloprion
              24487 Chromis (chromis)
              24561 Chrysiptera (demoiselles)
              24233 Dascyllus (dascyllus)
              24488 Dischistodus
              43692 Hemiglyphidodon
              25188 Hypsypops (garabaldi)
              99480 Lepidozygus
              25184 Mecaenichthys
              25187 Microspathodon
              24562 Neoglyphidodon
              24755 Neopomacentrus (demoiselles)
              25189 Nexilosus
              25190 Parma (scalyfins)
              24817 Plectroglyphidodon
              24000 Pomacentrus
              24271 Pomachromis (reef-damsels)
              25070 Pristotis
              28281 Similiparma
              23999 Stegastes (gregories)
              25069 Teixeirichthys
        Clownfishes => 24566 Amphiprion
              26513 Premnas
        Gobies => 5319 Gobiidae
        Jawfish => 5278 Opistognathidae
        dragonet => 5363 Callionymidae
        Blenny =>
              5368 Blenniidae: combtooth blennies, including the sabre-toothed blennies.
              5353 Chaenopsidae: pikeblennies, tubeblennies and flagblennies.
              5342 Clinidae: clinids, including the giant kelpfish.
              5338 Dactyloscopidae: sand stargazers.
              5304 Labrisomidae.
              5191 Tripterygiidae: threefin blennies.
        Sweeper => 5273 Pempheridae
        Hawkfish => 5343 Cirrhitidae
        Wrasses => 5305 Labridae
        Parrotfishes => 5214 Scaridae
        Triggerfishes => 5061 Balistidae
        Surgeonfishes =>
              24009 Acanthurus +
              !!!!MISSING !!! Callicanthus +
              25623 Ctenochaetus +
              !!!MISSING !!! Cyphomycter +
              39830 Hepatus +
              28096 Paracanthurus +
              25084 Prionurus +
              24346 Zebrasoma +
        Unicornfishes => naso
        filefishes => 5058 Monacanthidae
        Boxfishes => 5057 Ostraciidae
        Burrfish => 18092 Chilomycterus
        porcupinefishes => 25047 Diodon
        pufferfishes => 5056 Tetraodontidae
        Sea turtles =>
               8123 Cheloniidae
               8126 Dermochelyidae
        Staghorn, elkhorn and finger corals =>
               6728 Acroporidae
               1845 Poritidae
               1841 Pocilloporidae
        Flower, brain and pillar corals =>
              8931 Siderastreidae +
            6586   Mussidae +
            6645 Faviidae
            6595 Meandrinidae
            6711 Astrocoeniidae
        Tube, branch and leaf corals =>
            1808 Oculinidae
            6690 Caryophylliidae
            6724 Agariciidae
            6660 Dendrophylliidae
        Crustaceans =>
            !!MISSING !! Thylacocephala
            265 Branchiopoda
            1495 Remipedia
            278 Cephalocarida
            1353 Maxillopoda
            1456 Ostracoda
            1157 Malacostraca
        Soft corals =>
            1760 Alcyonacea
        Jellyfish =>
            6681 Cubozoa
            1795 Hydrozoa
            !!!MISSIGN !!! Polypodiozoa
            1802 Scyphozoa
            6601 Staurozoa
        nudibranchs => 2538 Nudibranchia
        octopus and squid =>
            2312 Cephalopoda
        sponges =>
            3142 Porifera
        tunicates, sea stars, worms and anemones =>
            64963 Appendicularia
            1486 Ascidiacea
            !!MISSING Sorberacea
            1574 Thaliacea
            1927 Asteroidea
            142 Sabellidae
            1747 Actiniaria
            58544 HErmodice (fireworm)
      lionfises and scorpionfishes and rockfishes  => 5120 scorpaeniformes
      sea urchins => 1971 Echinoidea
=end


        #species group list of eolid ancestors
        species_groups = {
          "sharks" => [1857],
          "sharks commenseals" => [5361,5331,5216],
          "rays" =>[8898, 1864, 1858],
          "tarpon and bonefish" => [23987, 2776871],
          "eels" => [8280],
          "barracudas" => [24821],
          "Snook" => [5355],
          "slim-bodied fishes" => [5192, 216494, 216495, 17480, 5068, 5066, 8244, 8246],
          "cardinalfishes" => [5377],
          "squirrelfishes" => [23827, 24504, 24317],
          "hamlets" => [25212],
          "seabasses and basslets" => [24577, 101429, 24494, 25641, 26407, 26889, 27161, 26464, 25356, 26848, 24688,
            24147, 28418, 27749, 24685, 25417, 27748, 27762, 25208, 28602, 27436, 26361, 25426, 25212, 4571002, 26625,
            25357, 24757, 4571215, 26331, 25427, 25358, 24799, 28035, 28401, 24681, 25207, 26315, 24493, 26465, 26463,
            25546, 24984, 27215, 28273, 26789, 28472, 27750, 23804, 108840, 26773, 28496, 26763,
            204766, 206645, 224729, 204582, 5318],
          "bigeyes" => [5221],
          "groupers" => [24039, 24689, 27865, 25416, 24424, 99524, 26620, 24209, 23843, 27113, 26375, 24679, 24210, 28230, 24787, 26822, 26823, 101681, 23960],
          "jacks" => [5361],
          "snapper" => [5294, 344840, 206429, 205264],
          "grunts" => [5317, 5127],
          "goatfishes" => [5286],
          "porgies" => [5203],
          "drums" => [5211],
          "flatfish" => [5168],
          "butterflyfishes" => [5352],
          "spadefish" => [5324],
          "angelfishes" => [25498, 5260],
          "damselfishes" => [24246, 26865, 28078, 24247, 28021, 27418, 99481, 24487, 24561, 24233, 24488, 43692, 25188,
            99480, 25184, 25187, 24562, 24755, 25189, 25190, 24817, 24000, 24271, 25070, 28281, 23999, 25069],
          "clownfishes" => [24566, 26513],
          "gobies" => [5319],
          "jawfish" => [5278],
          "dragonets" => [5363],
          "blenny" => [5368, 5353, 5342, 5338, 5304, 5191],
          "sweeper"=> [5273],
          "hawkfish" => [5343],
          "wrasses" => [5305],
          "parrotfishes" => [5214],
          "triggerfishes" => [5061],
          "surgeonfishes" => [24009, 25623, 39830, 28096, 25084, 24346],
          "unicornfishes" => [24563],
          "filefishes" => [5058],
          "boxfishes" => [5057],
          "burrfish" => [18092],
          "porcupinefishes" => [25047],
          "pufferfishes" => [5056],
          "sea turtles" => [8123, 8126],
          "staghorn, elkhorn and finger corals" => [6728, 1845, 1841],
          "flower, brain and pillar corals" => [8931, 6586, 6645, 6595, 6711],
          "tube, branch and leaf corals" => [1808, 6690, 6724, 6660],
          "crustaceans" => [265, 1495, 278, 1353, 1456, 1157],
          "soft corals" => [1760],
          "jellyfish" => [6681,  1795, 1802, 6601],
          "nudibranchs" => [2538],
          "octopus and squid" => [2312],
          "sponges" => [3142],
          "tunicates, sea stars, worms and anemones" => [64963, 1486, 1574, 1927, 142, 1747, 58544],
          "lionfises and scorpionfishes and rockfishes" => [5120],
          "sea urchins" => [1971],
          "other"=>[1]
        }
    end

  def species_group_hash
    inverted_list = {}
    self.species_groups.each do |group|
      group[1].each do |id|
        inverted_list[id.to_s] = group[0]
      end
    end
    return inverted_list
  end


  def lookup_category
    ## this method will give the category of a species, it was used to generate the tags in the "category" column
    ## this will fail for the species in the group hash so I did this in console:
    ##hash= Eolsname.find(1).species_group_hash
    ##hash.keys.each {|k|
    ##a=Eolsname.find(k.to_i);
    ##a.category = hash[k]
    ##a.save
    ##}
    eol_ancestors = self.eolid_ancestors.reverse ## we need to start bottom up
    if eol_ancestors.blank?
      return "unclassified"
    else
      groups = self.species_group_hash
      eol_ancestors.each do |ancestor|
        if !groups[ancestor.to_s].nil?
          return groups[ancestor.to_s]
        end
      end
    end
    return "other"
  end

  #####
  #####  END OF METHODS to regeneratr the "category" column
  #####


  def permalink
    "/pages/species/#{blob}"
  end
  def blob
    if sname.blank?
      "unnamed-species-#{shaken_id}"
    else
      "#{sname.to_url}-#{shaken_id}"
    end
  end
  def fullpermalink option=nil
    HtmlHelper.find_root_for(option).chop + permalink
  end
  def shaken_id
    "F#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "F"
       i =  Mp.deshake(code[1..-1])
    else
       i = Integer(code.to_s, 10)
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      return i
    end
  end




end
