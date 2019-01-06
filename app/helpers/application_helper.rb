module ApplicationHelper

  def compare_tripname(name1, name2)
    if name1.blank? && name2.blank?
      return true
    end
    if name1.blank? || name2.blank?
      return false
    end

    if name1.downcase.gsub(" ","") == name2.downcase.gsub(" ","")
      return true
    else
      return false
    end
  end

  def auto_file_versionning(filename)
    begin
      start_time = Time.now
      mtime = File.stat("public/"+filename).mtime

      Rails.logger.debug "auto_file_versionning read time: #{(1000*(Time.now - start_time)).round(3).to_f}ms"
      if !mtime.nil? && mtime.to_i > 0 then
        return HtmlHelper.lbroot "#{filename}?v=#{mtime.to_i}"
      else
        return HtmlHelper.lbroot filename
      end
    rescue
      return filename
    end
  end

  def show_notes
    return     !(@dive.notes.nil? || @dive.notes.empty?) && (((@user.nil? || (!@user.nil? && @user.id != @owner.id)) && @owner.share_details_notes) || (!@user.nil? && @user.id == @owner.id))
  end

  def wiki_links_update wikitext
    ##will process the various links and replace them accordingly
    wikitext = wikitext.gsub(/fish\:\/\/(?<id>[0-9]*)/, 'http://www.eol.org/\k<id>')
    #wikitext = wikitext.gsub(/country\:\/\/(?<id>[0-9]*)/, 'http://www.eol.org/\k<id>')
    ##test
    wikitext = wikitext.gsub(/country\:\/\/[0-9]*/){|c|
        begin
          country = Country.find(c.match("\/([0-9]*)$")[1]).blob
          c = ROOT_URL+"pages/spots/"+country
        rescue
          c = ROOT_URL+"pages/spots"
        end
      }
      wikitext = wikitext.gsub(/spot\:\/\/[0-9]*/){|c|
          begin
            spot = Spot.find(c.match("\/([0-9]*)$")[1])
            c = ROOT_URL+"pages/spots/#{spot.country.blob}/#{spot.location.blob}/#{spot.blob}"
          rescue
            c = ROOT_URL+"pages/spots"
          end
        }
      wikitext = wikitext.gsub( /<([\/ ]*)h4/, "<\\1h5")
      wikitext = wikitext.gsub( /<([\/ ]*)h3/, "<\\1h4")
      wikitext = wikitext.gsub( /<([\/ ]*)h2/, "<\\1h3")
      wikitext = wikitext.gsub( /<([\/ ]*)h1/, "<\\1h2")

    return wikitext.html_safe ## needed since the latest update on rails
  end
  def ensure_url url
    if url.match(/^http:\/\//)
      return url
    else
      return "http://"+url
    end
  end

  def ff11osx?
    ##checks if we're talking to stupid FF 11+ on OSX
    ## https://bugzilla.mozilla.org/show_bug.cgi?id=738392
    begin
     myua = request.user_agent.match(/^Mozilla.*Macintosh.*FireFox\/([0-9\.]*)$/i)
     return !myua.nil? && myua[1].to_f >= 11.0 && myua[1].to_f < 12.0
    rescue
      return false
    end
  end

  def generate_fish_list_for_dive(dive)
    fish_list = []

    dive.eolcnames.each do |c|
      s = c.eolsname
      fish_list << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank, :category => s.category}
    end
    dive.eolsnames.each do |s|
      fish_list << {:id => "s-#{s.id}", :sname => s.sname, :cnames => s.eolcnames.map(&:cname), :preferred_name => s.preferred_cname, :picture => s.thumbnail_href, :bio => s.eol_description, :url => s.url, :rank => s.taxonrank, :category => s.category}
    end

    return fish_list
  end

  def blog_reformat wikitext
    wikitext = wikitext.gsub( /\n/, "<br/>")
    return wikitext.html_safe
  end


  def display_all_error_messages(object, method)
    list_items = object.errors[method].map { |msg| content_tag(:li, msg) }
    content_tag(:ul, list_items.join.html_safe)
  end


  def config_translate section, key
    @@config_translate_texts ||= YAML.load_file "#{Rails.root}/config/config_translate.yml"
    text = @@config_translate_texts[section.to_s][key.to_s]
    return text unless text.nil?
    return key
  end

  def config_translate_labels sections=nil
    @@config_translate_texts ||= YAML.load_file "#{Rails.root}/config/config_translate.yml"
    return @@config_translate_texts unless sections
    excerpt = {}
    sections.each do |section|
      excerpt[section.to_s] = @@config_translate_texts[section.to_s]
    end
    return excerpt
  end

end




