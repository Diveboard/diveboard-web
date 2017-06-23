DiveBoard::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  #config.cache_store = :file_store, File.join(::Rails.root.to_s, 'tmp', 'cache')
  config.cache_store = :redis_store, 'redis://localhost:6379/0/cache', { expires_in: 60.days }

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)

  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "localhost" 
    }
    
  config.current_machine_name = `hostname -s`.chop ## we need to divfferentiate machines

  config.mailer_log_mailto = [ "support@diveboard.com" ]
  config.mailer_log_prefix = "[#{config.current_machine_name}][PROD][MAIL] ---SHOULD NOT HAPPEN--- "
  config.plugin_log_mailto = [ "logs@diveboard.com" ]
  config.plugin_log_prefix = "[#{config.current_machine_name}][PROD][PLUGIN]"
  config.workers_log_prefix = "[#{config.current_machine_name}][PROD][WORKER]"
  config.dan_export_mailto = [ "diveboard@dan.org", "logs@diveboard.com" ]
  config.dan_export_prefix = "[#{config.current_machine_name}][PROD][DAN]"
  config.mailer_baskets_bcc = ['pascal@diveboard.com', 'alex@diveboard.com']

  config.google_cloud_buckets = {
      :pictures => ['st0.diveboard.com','st1.diveboard.com','st2.diveboard.com','st3.diveboard.com', 'st4.diveboard.com','st5.diveboard.com','st6.diveboard.com','st7.diveboard.com','st8.diveboard.com','st9.diveboard.com'],
      :originals => 'cache-pics-orig'
    }  

  config.default_storage_per_dive = 2.megabyte
  config.default_storage_per_month = 500.megabyte
  config.max_orphan_size = 1.gigabyte

  config.workers_count = 4
  config.workers_process_name = "delayed_job_worker.production"
  config.workers_maxqueue_warn= 100
  config.workers_maxold_warn = 4.hours
  
  config.stats_path = "/var/log/nginx"
  config.stats_pattern = /^access\.log[0-9gz.]*$/

#  config.middleware.use ExceptionNotifier,
#    :email_prefix => "[#{config.current_machine_name}][PROD][WEB] ",
#    :sender_address => %{"Exception Notifier" <root@prod.diveboard.com>},
#    :exception_recipients => %w{logs@diveboard.com}
  
  Jammit.set_package_assets(true);
  config.assets.debug = false
  config.assets.digest = true

  config.paypal = {
    :url => "https://paypal.com/webapps/adaptivepayment/flow/pay",
    :receiver_email => 'alex@diveboard.com',
    :api_host => "svcs.paypal.com", #svcs.paypal.com
    :api_3t_host => "api-3t.paypal.com", #svcs.paypal.com
    :api_3t_url => 'https://www.paypal.com/cgi-bin/webscr',
    :api_username => 'alex_api1.diveboard.com',
    :api_password => ENV["PAYPAL_API_PASSWORD"], 
    :api_signature => ENV["PAYPAL_API_SIGNATURE"],
    :app_id => ENV["PAYPAL_API_APPID"],
    :delay_pending_before_cancel => 1.day
  }

  #config.balancing_roots = ["http://www1.diveboard.com/", "http://www2.diveboard.com/", "http://www3.diveboard.com/"]
  
  #WARNING // cannot be used here - > it's used when maps are on og:image and fb doesn not recognize //cnd.xxxx as valid URL
  #hence we're defaulting to https
  config.balancing_roots = ["https://cdn.diveboard.com/", "https://cdn1.diveboard.com/", "https://cdn2.diveboard.com/", "https://cdn3.diveboard.com/", "https://cdn4.diveboard.com/", "https://cdn5.diveboard.com/", "https://cdn6.diveboard.com/"]
  config.explore_balancing_roots = ["//www1.diveboard.com", "//www2.diveboard.com", "//www3.diveboard.com"]
end
FB_APP_KEY = ENV["FB_APP_KEY"] 
FB_APP_SECRET = ENV["FB_APP_SECRET"] 
FB_APP_ID = ENV["FB_APP_ID"] 
FB_COMMENT = ENV["FB_COMMENT"]


GOOGLE_LEGACY_ANALYTICS = "UA-20925317-1"
GOOGLE_ANALYTICS = "UA-20925317-2"
GOOGLE_MAPS_API = ENV["GOOGLE_MAPS_API"]


ROOT_DOMAIN = "www.diveboard.com" #used for google analytics cookies
ROOT_URL = "http://www.diveboard.com/" #used in model from console
COOKIES_DOMAIN = ".diveboard.com"
LOCALE_ROOT_URL = "http://%{locale}.diveboard.com/"
ROOT_TINY_URL = "http://scu.bz/"
ROOT_MOBILE_DOMAIN = "m.diveboard.com"

#For flickr
FLICKR_KEY = ENV["FLICKR_KEY"]
FLICKR_SECRET = ENV["FLICKR_SECRET"]


NOTIFICATION_MAIL_FILTER = ''


DISABLE_CAPTCHA = false
SERVER_IP = "88.190.16.186"

TOKEN = "token_#{Rails.env}".to_sym ## avoid having the token from .diveboard.com sent on the wrong domain...


DiveBoard::Application.middleware.use Oink::Middleware

DISQUS_PREFIX = "diveboard"
DISQUS_SECRET_KEY = ENV["DISQUS_SECRET_KEY"]
DISQUS_PUBLIC_KEY = ENV["DISQUS_PUBLIC_KEY"]


MOVESCOUNT_API_KEY = ENV["MOVESCOUNT_API_KEY"]
MOVESCOUNT_URL = "http://www.movescount.com/"
MOVESCOUNT_REST_URL = "https://uiservices.movescount.com/"
MOVESCOUNT_REDIRECT_URI = "http://www.diveboard.com/api/v2/movescount"

TREASURE_SHOPS = [9378, 4288, 943]
