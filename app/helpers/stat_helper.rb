module StatHelper

  PATH = Rails.configuration.stats_path
  FILE_PATTERN = Rails.configuration.stats_pattern
  BATCH_INSERT = 2000

  CASE_BOT_SQL = <<ESQL
WHEN ip in (
  '204.93.223.151', #newrelic
  '88.190.23.118', #vm.diveboard.com
  '88.191.143.60', #ksso.net
  '127.0.0.1', #localhost
  '88.191.120.205', #test server
  '88.190.16.186' #prod.diveboard.com
  ) THEN NULL
WHEN user_agent like '%bot%' then NULL
WHEN status >= 300 and status != 304 then NULL  #304 is Not Modified
WHEN user_agent = 'Ruby' then NULL
WHEN user_agent = 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)' THEN NULL
WHEN user_agent REGEXP 'Baiduspider' then NULL
ESQL

  CATEG_SQL = <<ESQL
CASE
#{CASE_BOT_SQL}
WHEN url REGEXP '\\.php$' then NULL
WHEN url REGEXP '^(https?://www.diveboard.com)?/+wp-content/' then NULL
WHEN url REGEXP '^(https?://www.diveboard.com)?/+map_images/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+robots.txt' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+crossdomain.xml' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+opensearch.xml' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+sitemap.xml.gz' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+img/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+images/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+tmp_upload/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+user_images/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+elrte/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+assets/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+mod/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+js/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+javascripts/' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+ie7/' then NULL
WHEN url REGEXP '^(https?://www.diveboard.com)?/+style/' then NULL
when url REGEXP '/profile.svg$' then NULL
when url REGEXP '/profile.png$' then NULL
when url = '/' then 'home'
when url REGEXP '/update.json$' then 'api'
when url REGEXP '/delete.json$' then 'api'
when url REGEXP '^/[^/]*/bulk$' then 'api'
when url REGEXP '^/[^/]*/feed$' then 'api'
when url REGEXP '/create.json$' then 'api'
when url REGEXP '^(https?://www.diveboard.com)?/+explore/gallery' then 'gallery'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+explore(/|$)' then 'explore'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+pages/' then 'explore'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+search(/|$)' then 'search'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+blog(/|$)' then 'blog'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+community(/|$)' then 'blog'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+api/' then 'api'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+api/stats_trace' then NULL
WHEN url REGEXP '^(https?://www.diveboard.com)?/+login(/|$)' then 'login'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+wp-login.php$' then 'login'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+about/tour' then 'tour'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+about(/|$)' then 'about'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+plugin(/|$)' then 'about'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+settings(/|$)' then 'settings'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+admin(/|$)' then 'admin'
WHEN url REGEXP '^(https?://www.diveboard.com)?/+mon(/|$)' then 'admin'
when url REGEXP '^(https?://www.diveboard.com)?/+pro/*$' then 'commercial_pro'
when url REGEXP '^(https?://www.diveboard.com)?/+pro/+[^/]+' then 'shop_page'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/trip/[0-9]*-' then 'trip'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/new/?$' then 'new_dive'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/partial/new/?$' then 'new_dive'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/partial/[0-9]*(/|$)' then 'dive_page'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/pictures/[0-9]*(/|$)' then 'dive_page'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/play_vid/[0-9]*(/|$)' then NULL
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/[0-9]*(\.js)?(/|$)' then 'dive_page'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/D[0-9A-Za-z]*(/|$)' then 'dive_page'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/valid_claim(/|$)' then 'home_logbook'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/widget.*$' then 'widgets'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/posts(/|$)' then 'blog'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*/form_review(/|$)' then 'api'
when url REGEXP '^(https?://www.diveboard.com)?/+u/[^/]*$' then 'home_logbook'
when url REGEXP '^(https?://www.diveboard.com)?/+[^/]*$' then 'home_logbook'
ELSE NULL END
ESQL

  def self.load_from_access current_path = nil
    # From the latest entry in stats_logs or stats_sums (which should be almost one hour before stats_logs, but useful in case of truncate)
    start_time = ActiveRecord::Base.connection.select_one('select max(m) as m2 from (select max(time) as m from stats_sums  UNION ALL  select max(time) as m from stats_logs) t')['m2'] || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round).utc
    Rails.logger.info "Loading from #{start_time} to #{stop_time}"

    vals = []
    line = nil
    matched = nil
    files = []
    read_next_file = true
    current_path ||= PATH

    # Looking for files to parse
    Dir.foreach(current_path) do |filename|
      next unless filename =~ FILE_PATTERN
      files.push filename
    end

    #sorting the files in reverse time order
    files.sort! do |a,b| (a.match(/[0-9]+/)[0].to_i rescue 0) - (b.match(/[0-9]+/)[0].to_i rescue 0) end

    files.each do |filename|
      begin
        Rails.logger.debug "Importing logs from #{filename}"
        file = nil
        vals = []
        prev_date = nil
        sub_count = 0
        if filename =~ /\.gz$/ then
          file = Zlib::GzipReader.open(current_path+"/"+filename)
        else
          file = File.open(current_path+"/"+filename, "r") unless filename =~ /\.gz$/
        end
        while true do
          line = file.readline
          matched = line.match /^([0-9.]*) - [^ ]* \[(.*)\] "([^ ]*) ([^"?]*)(\?([^"]*))? [^"]*" ([0-9]*) [0-9]* "([^"]*)" "([^"]*)"/
          next unless matched
          ip, date, method, url, params_with_mark, params, status, ref, user_agent = matched[1..-1]
          date = date.gsub(/^([^\/:]*\/[^\/:]*\/[^\/:]*):/, "\\1 ").to_datetime

          # Try not to import a line twice. Do not read more file if we have imported all the timespan required
          read_next_file = false if date < start_time
          next unless start_time.nil? || date > start_time
          next unless stop_time.nil?  || date < stop_time

          # sub counter for requests coming at the same second
          if prev_date == date then
            sub_count += 1
            prev_date = date
          else
            sub_count = 0
            prev_date = date
          end

          #adding the stuff to insert into the DB
          vals.push ({:ip => ip, :time => date, :sub_count => sub_count, :method => method, :url => url, :params => params, :status => status, :ref => ref, :user_agent => user_agent})
          if vals.count > BATCH_INSERT then
            previous_log_level = Rails.logger.level
            Rails.logger.level = 1 if Rails.logger.level == 0
            Media.insert_bulk_sanitized 'stats_logs', vals
            Rails.logger.level = previous_log_level
            vals = []
          end
        end
      rescue EOFError
        nil
      rescue
        Rails.logger.error $!.message
        Rails.logger.debug line
        Rails.logger.debug matched[1..-1]
        Rails.logger.debug $!.backtrace.join "\n"
      end
      Media.insert_bulk_sanitized 'stats_logs', vals if vals.count > 0
      break if !read_next_file
    end
  end

  def self.aggreg
    #Changing the transaction isolation level for improved perf and better mornings
    ActiveRecord::Base.connection.reset!
    ActiveRecord::Base.connection.execute "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;"


    aggreg = 'categ'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round-3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%3600) as t,
      #{CATEG_SQL} as cat, NULL, count(*)
      from stats_logs
      where time >= :start and time < :end
      group by cat, t
      having cat is not null", :start => start_time, :end => stop_time

    aggreg = 'visits'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%(24*3600))).round-24*3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%(24*3600)) as t,
      'distinct_daily_ip', NULL, count(distinct ip)
      from stats_logs
      where time >= :start and time < :end and #{CATEG_SQL} IS NOT NULL
      group by t", :start => start_time, :end => stop_time

    aggreg = 'user'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round-3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%3600) as t,
      substr(url, 2, case when locate('/', url,2) = 0 then LENGTH(url) else locate('/', url,2)-2 end) as vanity,
      #{CATEG_SQL} as cat, count(*)
      from stats_logs
      where time >= :start and time < :end
      group by cat, t
      having cat in ('dive_page', 'home_logbook', 'trip')", :start => start_time, :end => stop_time

    aggreg = 'shop'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round-3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%3600) as t,
      SUBSTRING_INDEX(SUBSTRING_INDEX(url,'/',3), '/',-1) as vanity,
      #{CATEG_SQL} as cat, count(*)
      from stats_logs
      where time >= :start and time < :end
      group by cat, t
      having cat in ('shop_page')", :start => start_time, :end => stop_time

    aggreg = 'ad'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round-3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%3600) as t,
      substring_index(substring_index(url, '/', -2), '/', 1) as ad_id,
      substring_index(url, '/', -1) as cat, count(*)
      from stats_logs
      where time >= :start and time < :end and url like '/api/stats_trace/ad_explore/%'
      group by cat, t", :start => start_time, :end => stop_time


    aggreg = 'widgets'
    start_time = Media.select_all_sanitized('select max(time) as m from stats_sums where aggreg = :val', :val => aggreg).first['m'] + 1.hour || "1900-01-01".to_datetime rescue "1900-01-01".to_datetime
    stop_time = Time.at((Time.now.utc.to_f-(Time.now.utc.to_f%3600)).round-3600)
    Media.execute_sanitized "insert into stats_sums (aggreg, time, col1, col2, nb)
      select '#{aggreg}', from_unixtime(unix_timestamp(time)-unix_timestamp(time)%3600) as t,
      SUBSTR(ref, 1, locate('/', concat(ref, '/'), 9)-1) as cat1, substr(url, 13, locate('/', url, 13)-13) as cat2, count(*)
      from stats_logs
      where time >= :start and time < :end
      and #{CATEG_SQL} is not null
      group by cat1, cat2, t", :start => start_time, :end => stop_time


    ActiveRecord::Base.connection.reset!
  end

end



#  FOR CORRELATION CALCULUS
#
#  => Chi square test
#
#  select sum(X2) from (
#    select time,
#      pow(sum(case col1 when 'search' then nb else 0 end)-sum(nb)*S1/(S1+S2), 2)/(sum(nb)*S1/(S1+S2))   +
#      pow(sum(case col1 when 'explore' then nb else 0 end)-sum(nb)*S2/(S1+S2), 2)/(sum(nb)*S2/(S1+S2)) as X2
#    from stats_sums,
#    (select sum(case col1 when 'search' then nb else 0 end) as S1, sum(case col1 when 'explore' then nb else 0 end) as S2 from stats_sums) s
#    where col1='search' || col1='explore' group by to_days(time)
#  ) s;
#
#
#
#
#  function proba_from_chi_sq(x, df) {
#          var a, y, s;
#          var e, c, z;
#          var even;                     /* True if df is an even number */
#
#          var LOG_SQRT_PI = 0.5723649429247000870717135; /* log(sqrt(pi)) */
#          var I_SQRT_PI = 0.5641895835477562869480795;   /* 1 / sqrt(pi) */
#
#          if (x <= 0.0 || df < 1) {
#              return 1.0;
#          }
#
#          a = 0.5 * x;
#          even = !(df & 1);
#          if (df > 1) {
#              y = ex(-a);
#          }
#          s = (even ? y : (2.0 * poz(-Math.sqrt(x))));
#          if (df > 2) {
#              x = 0.5 * (df - 1.0);
#              z = (even ? 1.0 : 0.5);
#              if (a > BIGX) {
#                  e = (even ? 0.0 : LOG_SQRT_PI);
#                  c = Math.log(a);
#                  while (z <= x) {
#                      e = Math.log(z) + e;
#                      s += ex(c * z - a - e);
#                      z += 1.0;
#                  }
#                  return s;
#              } else {
#                  e = (even ? 1.0 : (I_SQRT_PI / Math.sqrt(a)));
#                  c = 0.0;
#                  while (z <= x) {
#                      e = e * (a / z);
#                      c = c + e;
#                      z += 1.0;
#                  }
#                  return c * y + s;
#              }
#          } else {
#              return s;
#          }
#      }#
