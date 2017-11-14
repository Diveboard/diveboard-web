DiveBoard::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true
  config.cache_store = :file_store, File.join(::Rails.root.to_s, 'tmp', 'cache')

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  #config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "localhost" 
    }

  config.log_level = :debug

  config.include_local_js = true

  config.mailer_log_mailto = [ "diveboard@mailinator.com" ]
  config.mailer_log_prefix = "[DEV][MAIL]"
  config.plugin_log_mailto = [ "diveboard@mailinator.com" ]
  config.plugin_log_prefix = "[DEV][PLUGIN]"
  config.workers_log_prefix = "[DEV][WORKER]"
  config.dan_export_mailto = [ "diveboard@mailinator.com" ]
  config.dan_export_prefix = "[DEV][DAN]"
  config.mailer_baskets_bcc = []

  config.google_cloud_buckets = {
      :pictures => ['picts'],
      :originals => 'picts'
    }

  config.default_storage_per_dive = 2.megabyte
  config.default_storage_per_month = 500.megabyte
  config.max_orphan_size = 1.gigabyte

  config.workers_count = 1
  config.workers_process_name = "delayed_job_worker.dev_local"
  config.workers_maxqueue_warn= 100
  config.workers_maxold_warn = 4.hours

  config.stats_path = "/tmp"
  config.stats_pattern = /^nginx_access\.log[0-9gz.]*$/

  
  config.middleware.use ExceptionNotifier,
    :email_prefix => "[DEV][WEB] ",
    :sender_address => %{"Exception Notifier" <root@mailinator.com},
    :exception_recipients => %w{null@mailinator.com}
  
  #config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "smtp.mailinator.com",
    :port                 => 25 
  }

  Jammit.set_package_assets(false);
  config.assets.debug = true
  config.sass.debug_info = true
  config.assets.compress = false

  config.paypal = {
    :url => "https://www.sandbox.paypal.com/webapps/adaptivepayment/flow/pay",
    :hosted_button_id => "72Y6RPQH4BVSN",
    :receiver_email => 'alex_1361026587_biz@diveboard.com',
    :api_host => "svcs.sandbox.paypal.com", #svcs.paypal.com
    :api_3t_host => "api-3t.sandbox.paypal.com", #svcs.paypal.com
    :api_3t_url => 'https://www.sandbox.paypal.com/cgi-bin/webscr',
    :api_username => 'alex_1361026587_biz_api1.diveboard.com',
    :api_password => '1361026611',
    :api_signature => 'AFcWxV21C7fd0v3bYYYRCpSSRl31A9QferbRdjJcpBzKIBTipjHysudw',
    :app_id => 'APP-80W284485P519543T',
    :delay_pending_before_cancel => 1.day
  }

  config.balancing_roots = ["https://dev.diveboard.com/"]
  config.explore_balancing_roots = ["https://dev.diveboard.com/"]


  #config.balancing_roots = ["https://l.dev.diveboard.com/"]
end

ROOT_DOMAIN = "dev.diveboard.com" #used for google analytics cookies
ROOT_URL = "https://dev.diveboard.com/" #used in model from console
COOKIES_DOMAIN = ".dev.diveboard.com"
LOCALE_ROOT_URL = "http://%{locale}.dev.diveboard.com/"
ROOT_TINY_URL = "http://dev.scu.bz/"
ROOT_MOBILE_DOMAIN = "m.dev.diveboard.com"
# for Facebook Connect / Koala
FB_APP_KEY = "b7d52f545512e20c1c4db513662346fe" 
FB_APP_SECRET = "0393edcdf2baa2c291b9f33960991b1f" 
FB_APP_ID = "126856984043229"
FB_COMMENT = "kZ2wFTQb4cR"
#For gmaps
GOOGLE_ANALYTICS = "dummy_code"
GOOGLE_MAPS_API = "AIzaSyCI_HN-L1ZB6CHfaSv-Bh6EASdXg49qqZA"


#For flickr
FLICKR_KEY = "1e909244944c709829dba9f7215de0ec"
FLICKR_SECRET = "19cd64ad85a32745"

# Mail restriction on notifications by mails for other platforms than production (regexp)
NOTIFICATION_MAIL_FILTER = '@ksso|@diveboard'

DISABLE_CAPTCHA = true

ENV['PATH']=ENV['PATH']+':/opt/local/bin:/opt/local/sbin'


TOKEN = "token_#{Rails.env}".to_sym ## avoid having the token from .diveboard.com sent on the wrong domain...

DISQUS_PREFIX = "testdiveboard"
DISQUS_SECRET_KEY = "4xQfOemWuyBC3wrIYPlBdsBzOYq4SPOtPRYr1OW9JoI0juVdfnYKPNmS2tPqPBPp"
DISQUS_PUBLIC_KEY = "TgLAFm125GpE7ORI7yl3I9jkXc5WaQjISmKtI8XrO4z8mzw7fVOXQF6RraRJLlfl"


MOVESCOUNT_REDIRECT_URI = "https://dev.diveboard.com/api/v2/movescount"
MOVESCOUNT_API_KEY = "TJiID2AAOuKqeVCygyltoySOv084oXjIX4cY8FMNSsAsEIin0EyMzTsv0EmM3Gl1"
MOVESCOUNT_URL = "http://partner-ui.movescount.com/"
MOVESCOUNT_REST_URL = "http://partner-rest.movescount.com"


TREASURE_SHOPS = [9378, 4288, 943]

SENDGRID_API ="NOEMAIL"