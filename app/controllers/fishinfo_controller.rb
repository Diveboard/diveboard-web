#this class answers to js CRUD queries around unitary fish data


class FishinfoController < ApplicationController
  before_filter :init_logged_user, :save_origin_url

  def fishsearch
    respond_to do |format|
      format.json {

        # check params[:tag] for the search pattern
        #@data = [{:key => "grouper", :value => "1"},
        #         {:key => "clown fish", :value => "2"},
        #         {:key => "shark whale", :value => "3"},
        #         {:key => "vampire fish", :value => "4"},
        #         {:key => "coelacanth", :value => "5"}]
        @result =[]
        if params[:q].blank? || (!params[:q].blank? && params[:q].length<3)
          Rails.logger.info "Fishsearch called with nothing to search or less than 3 characters"
          render :json => @result, :content_type => "text/html"
          return
        end
        query = CGI::unescapeHTML params[:q]
        #Rails.logger.debug { "query : #{query}" }
        #need to strip query for terms of under 2 characters (min infix)
        #query_s =""
        #query.split(" ").each do |elem| if elem.length > 1 then if query_s != "" then query_s = query_s + " "+elem else query_s = query_s + elem end end end
        query = query.split(" ").find_all{|s| s.length > 2}.join(" ")

        @fish = Eolcname.search(query, :per_page => 30).group_by(&:eolsname)
        @fish.each do |fish|
          cfish= fish[1][0]
          sfish= fish[0]
          if sfish != nil && %w(species genus).include?(sfish.taxonrank)
            @result << {:id => "c-"+cfish.id.to_s, :name => cfish.cname, :sname =>fish[0].sname, :picture => cfish.eolsname.thumbnail_href, :language => cfish.language, :eolid => cfish.eolsname.id.to_s, :rank => sfish.taxonrank, :fullpermalink => sfish.fullpermalink}

          end
        end
        @fish = Eolsname.search(query, :per_page => 30)
        @fish.each do |fish|
          if fish.preferred_cname == ""
            @result << {:id => "s-"+fish.id.to_s, :eolid =>fish.id.to_s,  :name => fish.sname, :sname =>"", :picture => fish.thumbnail_href, :language => "", :rank => fish.taxonrank, :fullpermalink => fish.fullpermalink}
          else
            @result << {:id => "s-"+fish.id.to_s, :eolid =>fish.id.to_s, :name => fish.sname, :sname =>fish.preferred_cname, :picture => fish.thumbnail_href, :language => fish.eolcnames[0].language, :rank => fish.taxonrank, :fullpermalink => fish.fullpermalink}
          end
        end
        render :json => @result, :content_type => "text/html"
      }
    end

  end

  def fishsearch_extended
    ## all local/global sorting will be done on the client side in js using the pre-generated occurence data
    logger.debug "fishinfo#fishsearch_extended starts "
    begin
      if params[:page].blank? then params[:page] = 1 end
      raise DBArgumentError.new "Don't know what to search for" if params[:id].blank? && params[:name].blank?
      params[:page_size] = 100 if params[:page_size].blank?

      if !params[:id].blank?
        r = params[:id].match(/^([s|c])\-([0-9]+)$/)
        if r[1] == "s"
          base_species = Eolsname.find(r[2].to_i)
        elsif r[1] =="c"
          base_species = Eolcname.find(r[2].to_i).eolsname
        end
        if !params[:scope].blank? && !base_species.nil?
          if params[:scope] == "children"
            result = base_species.children
          elsif params[:scope] == "siblings"
            result = base_species.parent.children rescue []
          elsif params[:scope] == "ancestors"
            result = base_species.all_parents
          else
            raise DBArgumentError.new "incorrect scope"
          end
        end
        ##we do not paginate ancestry search
        pagination = {:next => nil, :previous => nil, :total => result.count, :total_pages => 1, :current_page => 1}
      elsif !params[:name].blank?
        ##Sanaitize inputs - for some reason "(Platax pinnatus" is raising a sphinx error
        cleaned_name = params[:name].gsub(/[^a-z0-9]/i," ").gsub(/\ +/," ")
        query = cleaned_name.split(" ").find_all{|s| s.length > 2}.join(" ")
        result = []
        ## we include unclassified species since there are a lot which fail being classified
        result = Eolsname.search("#{query} @taxonrank species | unclassified",
            :match_mode => :extended,
            :per_page   => params[:page_size].to_i,
            :page => params[:page].to_i)
        if result.total_count > 1000
          ## WARNING Sphinx limits to 1000 results max http://freelancing-god.github.com/ts/en/advanced_config.html#large-result-sets
          total_results  = 1000
        else
          total_results = result.total_count
        end
        pagination ={:next => result.next_page, :previous => result.previous_page, :total => total_results, :total_pages => result.total_pages, :current_page => result.current_page}
      else
        raise DBArgumentError.new "not sure what to search..."
      end

      fish_list = []
      result.each do |s|
        fish_list << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank, :category => s.category}
      end
      render :json => {:success => true, :result => fish_list, :paginate => pagination}, :content_type => "text/html"
      return
    rescue
      render api_exception $!
      return
    end

  end

  def species_page
    ## for the time being.... we redirect to EOL ... until we have something better :)
    if params[:name].blank?
      redirect_to "/"
      return
    end
    begin
      species_id = Eolsname.idfromshake(params[:name].match(/\-([a-zA-Z0-9]+)$/)[1])
      redirect_to Eolsname.find(species_id).url
      return
    rescue
      redirect_to "/"
      return
    end
  end

  def add_missing_species
    ##EOL has changed ids - we can't ensure consistency
    render :json => {:success => false, :error => "functions temporarily disabled"}
    return
    if params[:species_eol_id].nil? || params[:species_eol_id].to_i.to_s != params[:species_eol_id]
      render :json => {:success => false, :error => "invalid species_eol_id"}
      return
    end
    if @user.nil?
      render :json => {:success => false, :error => "User must be logged to do this"}
      return
    end
    begin
      species_eol_id = params[:species_eol_id].to_i
      Eolsname.import_from_eol species_eol_id
      Rails.logger.debug "importing species #{species_eol_id}"
      Eolsname.find(species_eol_id).finalize_species_addition
      Rails.logger.debug "Launching async task to finish the job"
      render :json => {:success => true}
      return
    rescue
      render api_exception $!
    end

  end


end
