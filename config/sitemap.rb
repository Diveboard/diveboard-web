
(I18n.available_locales+[:canonical]).each do |locale|
  @locale = locale
  SitemapGenerator::Sitemap.default_host = HtmlHelper.find_root_for(locale).gsub(/\/$/, '')
  SitemapGenerator::Sitemap.sitemaps_path = "assets/sitemap/#{locale}"
  SitemapGenerator::Sitemap.sitemaps_path = "." if locale==:canonical
  SitemapGenerator::Sitemap.create do

    def alternate_links href
      I18n.available_locales.map do |locale|
        { href: HtmlHelper.find_root_for(locale).gsub(/\/$/, '') + href,
          lang: locale.to_s
        }
      end
    end

    if locale != :canonical
      def add_path href, opt
        opt2 = opt.dup
        opt2[:alternate] = alternate_links(href)
        add href, opt2
      end
    else
      def add_path *args
        add *args
      end
    end
    
    add_path '/', :changefreq => 'daily', :priority => 0.9
    add_path '/explore', :changefreq => 'daily', :priority => 0.9
    add_path '/explore/gallery', :changefreq => 'daily', :priority => 0.9
    add_path '/search', :changefreq => 'daily', :priority => 0.9
    add_path '/about', :changefreq => 'monthly', :priority => 0.9
    add_path '/about/import', :changefreq => 'monthly', :priority => 0.9

    User.where("vanity_url is not null").where("shop_proxy_id is null").find_each do |u|
      add_path u.permalink, :changefreq => 'weekly', :priority => 0.6
      u.dives.find_each do |d|
        next if d.privacy == 1
        next if d.spot_id == 1
        add_path d.permalink, :changefreq => 'monthly', :priority => 0.4
        d.pictures.each do |p|
            add(p.permalink, :images => [{
      :loc => p.large,
      :title => 'Scuba picture by #{u.nickname} in #{d.spot.name} in #{d.spot.country.cname}' }])
          end
      end
    end
  #  User.where("vanity_url is not null").where("shop_proxy_id is not null").find_each do |u|
  #    add_path u.permalink, :changefreq => 'weekly', :priority => 0.6
  #  end
    
    Shop.find_each do |u|
      next if u.user_proxy.nil?
      if u.reviews.empty?
        lastmod = u.updated_at
      else
        lastrev = u.reviews.order("UPDATED_AT DESC").first.updated_at
        if lastrev > u.updated_at
          lastmod = lastrev
        else
          lastmod = u.updated_at
        end
      end
      add_path u.user_proxy.permalink, :changefreq => 'weekly', :priority => 0.6, :lastmod => lastmod
    end
  
    BlogPost.where(:published => true).find_each do |b|
      add_path b.permalink, :changefreq => 'weekly', :priority => 0.6
    end
    Country.where("id > 1").find_each do |c|
      add_path c.permalink, :changefreq => 'weekly', :priority => 0.8
    end
    
    Location.where("id > 1 && country_id is not null").each do |c|
      add_path c.permalink, :changefreq => 'weekly', :priority => 0.8
    end
  
    Region.where("id > 1").each do |c|
      begin
        add_path c.permalink, :changefreq => 'weekly', :priority => 0.8
      rescue
        
      end
      
    end
  
    Spot.where("id > 1").find_each do |c|
      return unless c.is_visible_for?(nil)
      add_path c.permalink, :changefreq => 'weekly', :priority => 0.8
    end

    Area.all.each do |a|
      begin
        add_path a.permalink, :changefreq => 'weekly', :priority => 0.9
      rescue Exception => e
        
      end
    end
    GeonamesCountries.find_in_batches(batch_size: 50) do |bc|
      bc.each do |c|
        add_path "/area/#{c.name}-#{c.shaken_id}", :changefreq => 'weekly', :priority => 0.8
=begin
        country = Country.where("ccode like ?",c.ISO).first
        country.regions.find_in_batches(batch_size: 50) do |br|
          br.each do |r|
            add_path "/area/#{c.name}-#{c.shaken_id}/#{r.name}-#{r.shaken_id}", :changefreq => 'weekly', :priority => 0.8
            r.localSpots(country.id).each do |s|
              add_path "/area/#{c.name}-#{c.shaken_id}/#{r.name}-#{r.shaken_id}/#{s.name}-#{s.shaken_id}", :changefreq => 'weekly', :priority => 0.8
            end
          end
        end
=end
      end
    end

    GeonamesCore.where("feature_code like 'PPL%'").find_each do |g|
      add_path g.destinationLink , :changefreq => 'weekly', :priority => 0.8
    end
  end
end
SitemapGenerator::Sitemap.ping_search_engines
