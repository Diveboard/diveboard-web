xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    if @author.nil?
      xml.title It.it("Diveboard community pages", scope: ['blog', 'feed_rss'])
      xml.description It.it("The Diveboard SCUBA hangout: ask a question, share your thoughts... the floor is yours!", scope: ['blog', 'feed_rss'])
      xml.link ROOT_URL+"community"
    else
      xml.title It.it("%{nickname}'s activity on Diveboard", scope: ['blog', 'feed_rss'], nickname: @author.nickname)
      xml.description It.it("%{nickname}'s scuba posts and dives on Diveboard", scope: ['blog', 'feed_rss'], nickname: @author.nickname)
      xml.link ROOT_URL+@author.vanity_url+"/posts"
    end

    for post in @posts
      xml.item do
        xml.title post.title
        xml.description post.wiki_html
        xml.pubDate post.published_at.to_s(:rfc822)
        xml.link post.fullpermalink(:locale)
        xml.guid post.fullpermalink(:locale)
        xml.category "post"
      end
    end
    for dive in @dives

      buddies = ""
      begin
      JSON.parse(dive.buddies).each{|u| 
        begin 
          buddies+=u["name"]+", "
        rescue 
        end}
      rescue
      end
      begin
        if !dive.guide.blank?
          buddies+= @dive.guide+", "
        end
      rescue
      end
      buddies = buddies.chop.chop
      species = ""
      dive.eolcnames.map{|s| species+= s.cname+", "}
      dive.eolsnames.map{|s| species+= s.sname+", "}
      species = species.chop.chop
      begin
        if dive.user.share_details_notes
          notes = dive.notes.html_safe.gsub(/[\r|\t|\n]/," ")
        else
          notes = ""
        end
      rescue
        notes = ""
      end

      xml.item do
        xml.title It.it("%{user}'s scuba dive in %{spot_name}", scope: ['blog', 'feed_rss'], user: dive.user.nickname, spot_name: dive.spot.name.titleize)
        xml.description It.it("Dive spot: %{country}, %{location}, %{spot} - Depth: %{dive_maxdepth}m, duration: %{dive_duration}mins - buddies: %{buddies} - species spotted : %{species} - Notes: %{notes}", scope: ['blog', 'feed_rss'], country: dive.spot.country.cname.titleize, location: dive.spot.location.name.titleize, spot: dive.spot.name, dive_maxdepth: dive.maxdepth, dive_duration: dive.duration, buddies: buddies, species: species, notes: notes)
        xml.pubDate dive.created_at.to_s(:rfc822)
        xml.time_in dive.time_in.to_s(:rfc822)
        xml.duration dive.duration
        xml.link dive.fullpermalink(:locale)
        xml.guid dive.fullpermalink(:locale)
        xml.category "dive"
        xml.image_medium begin dive.featured_picture.medium rescue dive.static_map_url end
        xml.image_thumb dive.thumbnail_image_url
      end
    end
  end
end