
namespace :seo do

  desc "storing sample queries results over time"
  task :store_kpi  => :environment do |t, args|
    ["scuba logbook", "online scuba logbook", "dive in egypt", "dive in belize", "dive in cozumel", "dive in maldives", "dive in Bermuda", "dive in Bahamas", "easy dive antibes", "dive center miami beach", "dive center cozumel"].each do |keywords|
      gs = GSearchHelper::Parser.new keywords
      p = gs.position "diveboard.com"
      p ||= {:idx => nil, :url => nil}
      p[:keywords] = keywords
      p[:other] = gs.urls.to_json rescue nil
      Media.execute_sanitized "INSERT INTO seo_logs (lookup, date, idx, url, other) VALUES (:keywords, NOW(), :idx, :url, :other)", p
    end
  end

end
