class SpeciesPickerController < ApplicationController
  def species_occurences
    ##returns the species list that can be found in params[:lat], params[:lng] with a radius of params[:radius]
    ## lat is -90 .. +90
    ## long is -180 .. +180
    ## requesting fish_frequencies FishFrequency.all(:conditions => "lat>10 and lat < 20 and lng <20 and lng >10", :include => :eolsnames, :group => "gbif_id")
    begin
      lat = params[:lat].to_i
      lng = params[:lng].to_i
      radius = params[:radius].to_i

      if lat+radius > 90
        lat_clause = "lat >= #{(lat-radius)}"
      elsif lat-radius < -90
        lat_clause = "lat <= #{(lat+radius)}"
      else
        lat_clause = "lat <= #{(lat+radius)} AND lat >= #{(lat-radius)}"
      end
      if lng+radius > 180
        lng_clause ="lng >= #{(lng-radius)} OR lng <= #{(lng+radius-360)}"
      elsif lng-radius < -180
        lng_clause ="lng >= #{(lng-radius+360)} OR lng <= #{(lng+radius)}"
      else
        lng_clause ="lng >= #{(lng-radius)} AND lng <= #{(lng+radius)}"
      end

      fish_list = FishFrequency.all(:conditions => "(#{lat_clause}) AND (#{lng_clause}) AND ( eolsnames.worms_taxonrank = 'species' OR (eolsnames.worms_taxonrank is NULL and eolsnames.fishbase_taxonrank = 'species'))", :group => "gbif_id", :order => "count(*) desc", :joins => :eolsnames, :include => :eolsnames)
      species = {}
      fish_list.each do |o|
        begin
          s = o.eolsnames.first
          if species[s.category].nil? then species[s.category] = [] end
          p = s.parent
          species[s.category] << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :parent => { :id=> "s-#{p.id}", :sname => p.sname, :cnames => p.eolcnames.map(&:cname) , :preferred_name => p.preferred_cname, :picture => p.thumbnail_href} }
        rescue
        end
      end

      render :js => "local_species= #{species.to_json.html_safe};"
      return
    rescue
      render :html => "local_species={};\n/*ERROR : #{$!.message}*/"
    end
  end
end
