
# One sitemap of canonical www pages. The fr/es/zh subdomains declare the www page as their
# canonical URL, so they are not listed separately (search engines ignore hreflang links that
# point at non-canonical URLs).
SitemapGenerator::Sitemap.default_host = HtmlHelper.find_root_for(:canonical).gsub(/\/$/, '')
SitemapGenerator::Sitemap.sitemaps_path = "."

# Picture pages are left out while photos are served from the dead Google Cloud buckets
# (st0-9.diveboard.com). Set to true once the images load again.
include_pictures = false

SitemapGenerator::Sitemap.create do

  add '/', :changefreq => 'daily', :priority => 0.9
  add '/explore', :changefreq => 'daily', :priority => 0.9
  add '/explore/gallery', :changefreq => 'daily', :priority => 0.9
  add '/search', :changefreq => 'daily', :priority => 0.9
  add '/about', :changefreq => 'monthly', :priority => 0.9
  add '/about/import', :changefreq => 'monthly', :priority => 0.9

  # Public dives, and the profiles of users with at least one public dive (the rest are empty
  # profiles, many of them spam). Built from SQL rows rather than ActiveRecord objects: loading
  # every user and dive object crashed Ruby 1.9.3 (segfault in the GC). Same URLs as
  # User#permalink ("/<vanity_url>") and Dive#permalink ("/<vanity_url>/D<shaken id>").
  conn = ActiveRecord::Base.connection
  last_dive_id = 0
  loop do
    rows = conn.select_rows("SELECT d.id, u.id, u.vanity_url FROM dives d JOIN users u ON u.id = d.user_id " \
      "WHERE d.id > #{last_dive_id} AND d.privacy <> 1 AND d.spot_id <> 1 " \
      "AND u.vanity_url IS NOT NULL AND u.vanity_url <> '' AND u.shop_proxy_id IS NULL " \
      "ORDER BY d.id LIMIT 5000")
    break if rows.empty?
    rows.each do |dive_id, user_id, vanity_url|
      add "/#{vanity_url}/D#{Mp.shake(dive_id.to_i)}", :changefreq => 'monthly', :priority => 0.4
    end
    last_dive_id = rows.last[0].to_i
  end
  conn.select_rows("SELECT DISTINCT u.vanity_url FROM users u JOIN dives d ON d.user_id = u.id " \
    "WHERE d.privacy <> 1 AND d.spot_id <> 1 AND u.vanity_url IS NOT NULL AND u.vanity_url <> '' " \
    "AND u.shop_proxy_id IS NULL").each do |row|
    add "/#{row[0]}", :changefreq => 'weekly', :priority => 0.6
  end

  if include_pictures
    User.where("vanity_url is not null").where("shop_proxy_id is null").find_each do |u|
      u.dives.where("privacy <> 1 AND spot_id <> 1").find_each do |d|
        d.pictures.each do |p|
          add(p.permalink, :images => [{
            :loc => p.large,
            :title => "Scuba picture by #{u.nickname} in #{d.spot.name} in #{d.spot.country.cname}" }])
        end
      end
    end
  end
#  User.where("vanity_url is not null").where("shop_proxy_id is not null").find_each do |u|
#    add u.permalink, :changefreq => 'weekly', :priority => 0.6
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
    add u.user_proxy.permalink, :changefreq => 'weekly', :priority => 0.6, :lastmod => lastmod
  end

  BlogPost.where(:published => true).find_each do |b|
    add b.permalink, :changefreq => 'weekly', :priority => 0.6
  end
  Country.where("id > 1").find_each do |c|
    add c.permalink, :changefreq => 'weekly', :priority => 0.8
  end

  Location.where("id > 1 && country_id is not null").find_each do |c|
    add c.permalink, :changefreq => 'weekly', :priority => 0.8
  end

  Region.where("id > 1").find_each do |c|
    begin
      add c.permalink, :changefreq => 'weekly', :priority => 0.8
    rescue

    end
  end

  # Public spots only (private spots belong to one user's logbook), and not ones merged into another spot.
  # `next`, not `return`: returning from this block aborted the whole sitemap at the first hidden spot.
  Spot.where("id > 1 AND redirect_id IS NULL AND (flag_moderate_private_to_public IS NULL OR flag_moderate_private_to_public = 1)").find_each do |c|
    next unless c.is_visible_for?(nil)
    add c.permalink, :changefreq => 'weekly', :priority => 0.8
  end

  Area.all.each do |a|
    begin
      add a.permalink, :changefreq => 'weekly', :priority => 0.9
    rescue Exception => e

    end
  end
  GeonamesCountries.find_in_batches(batch_size: 50) do |bc|
    bc.each do |c|
      add "/area/#{c.name}-#{c.shaken_id}", :changefreq => 'weekly', :priority => 0.8
    end
  end

  # The ~3M geonames populated-place pages (GeonamesCore PPL*) are deliberately left out: they are
  # thin auto-generated pages and would swamp the real content in the crawl.
end
# No ping: Google and Bing retired their sitemap ping endpoints. The sitemap is declared in
# robots.txt and submitted in Search Console instead.
