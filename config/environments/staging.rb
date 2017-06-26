DiveBoard::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store = :redis_store, 'redis://localhost:6379/0/cache', { expires_in: 60.days }

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)

  #config.i18n.fallbacks = true

  #config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "localhost" 
    }

  config.log_level = :debug

  config.mailer_log_mailto = [ "logs@diveboard.com" ,"2_angel@bk.ru" ]
  config.mailer_log_prefix = "[STAGE][MAIL] "
  config.plugin_log_mailto = [ "logs@diveboard.com" ]
  config.plugin_log_prefix = "[STAGE][PLUGIN]"
  config.workers_log_prefix = "[STAGE][WORKER]"
  config.dan_export_mailto = [ "logs@diveboard.com","2_angel@bk.ru" ]
  config.dan_export_prefix = "[STAGE][DAN]"
  config.mailer_baskets_bcc = []

  config.google_cloud_buckets = {
      :pictures => ['cache-test-pics'],
      :originals => 'cache-test-pics-orig'
    }

  config.default_storage_per_dive = 2.megabyte
  config.default_storage_per_month = 500.megabyte
  config.max_orphan_size = 1.gigabyte

  config.workers_count = 3
  config.workers_process_name = "delayed_job_worker.staging"
  config.workers_maxqueue_warn= 100
  config.workers_maxold_warn = 4.hours
  
  config.stats_path = "/var/log/nginx"
  config.stats_pattern = /^access\.log[0-9gz.]*$/

  config.middleware.use ExceptionNotifier,
    :email_prefix => "[STAGE][WEB] ",
    :sender_address => %{"Exception Notifier" <root@dev.diveboard.com>},
    :exception_recipients => %w{alex@diveboard.com pascal@diveboard.com 2_angel@bk.ru}
  
  Jammit.set_package_assets(true);
  config.assets.debug = false
  config.assets.digest = true

  config.paypal = {
    :url => "https://www.sandbox.paypal.com/webapps/adaptivepayment/flow/pay",
    :hosted_button_id => "72Y6RPQH4BVSN",
    :receiver_email => 'pascal_1361026587_biz@diveboard.com',
    :api_host => "svcs.sandbox.paypal.com", #svcs.paypal.com
    :api_3t_host => "api-3t.sandbox.paypal.com", #svcs.paypal.com
    :api_3t_url => 'https://www.sandbox.paypal.com/cgi-bin/webscr',
    :api_username => 'pascal_1361026587_biz_api1.diveboard.com',
    :api_password => '1361026611',
    :api_signature => 'AFcWxV21C7fd0v3bYYYRCpSSRl31A9QferbRdjJcpBzKIBTipjHysudw',
    :app_id => 'APP-80W284485P519543T',
    :delay_pending_before_cancel => 1.day
  }

  config.balancing_roots = ["https://stage1.diveboard.com/", "https://stage2.diveboard.com/", "https://stage3.diveboard.com/"]
  config.explore_balancing_roots = ["//stage1.diveboard.com", "//stage2.diveboard.com", "//stage3.diveboard.com"]
end

ROOT_DOMAIN = "stage.diveboard.com" #used for google analytics cookies
ROOT_URL = "http://stage.diveboard.com/" #used in model from console
COOKIES_DOMAIN = ".stage.diveboard.com"
LOCALE_ROOT_URL = "http://%{locale}.stage.diveboard.com/"
ROOT_TINY_URL = "http://stage.scu.bz/"
ROOT_MOBILE_DOMAIN = "m.stage.diveboard.com"

SENDGRID_API = ENV["SENDGRID_API"]


TINY_PRIMES = [28657, 426389, 1686049, 94418953, 780291637, 2971215073]

# for Facebook Connect / Koala
FB_APP_KEY = "66c1d3c56998a9810db179bfbd76a9bd" 
FB_APP_SECRET = "7117bb9b21c314d5d19a3006bf754c1b" 
FB_APP_ID = "193803977296892"
FB_COMMENT = "kZ2wFTQb4cR"
#For gmaps
GOOGLE_ANALYTICS = "UA-40863960-1"
#GOOGLE_MAPS_API = "ABQIAAAAiwRWAKTreMgVAobGv71M5BTrjRLawgAEWBpRVRRaHhQhmAyOMRQ4IvPCAhMVNPveNBMS70ijYfvr-Q"
GOOGLE_MAPS_API = "AIzaSyCI_HN-L1ZB6CHfaSv-Bh6EASdXg49qqZA"


#For flickr
FLICKR_KEY = "1e909244944c709829dba9f7215de0ec"
FLICKR_SECRET = "19cd64ad85a32745"

NOTIFICATION_MAIL_FILTER = '@ksso|@diveboard'


DISABLE_CAPTCHA = true
SERVER_IP = "88.190.16.186"

TOKEN = "token_#{Rails.env}".to_sym ## avoid having the token from .diveboard.com sent on the wrong domain...



DiveBoard::Application.middleware.use Oink::Middleware

DISQUS_PREFIX = "diveboardstaging"
DISQUS_SECRET_KEY = "KqcWK8CXFIJEu4NqqKJONps9geRNOPgnHKrLWOk15ST51R1jslE65UwvJeqWRzKW"
DISQUS_PUBLIC_KEY = "ggA4DP61P6W26026KGOZtoUm446SM9H4C3nI2NZKLgRI9yJ7zzpFYI6CyKzLcTTC"


MOVESCOUNT_API_KEY = "9WzYYUdJuKjllKLU5OzEQae0y9veHJtlVOvjhqmOcczQIjpvNN1RkkA9SJAYy9cU"
MOVESCOUNT_URL = "http://partner-ui.movescount.com/"
MOVESCOUNT_REDIRECT_URI = "http://stage.diveboard.com/api/v2/movescount"
MOVESCOUNT_REST_URL = "http://partner-rest.movescount.com"

TREASURE_SHOPS = [9378, 4288, 943]