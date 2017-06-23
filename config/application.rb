#encoding: UTF-8
#Overloading Jammit IE versions for MHTML/DATA_URI
module Jammit
  module Helper
    DATA_URI_START = "<!--[if (!IE)|(gte IE 9)]><!-->"
    MHTML_START    = "<!--[if lte IE 8]>"
  end
end


require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'rack/throttle'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module DiveBoard
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]


    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    ## config.middleware.use Rack::Throttle::Interval, :min => 1.0, :cache => GDBM.new('tmp/throttle.db') ##at least 1 second between each query
    
    # There are 2 ways to access google cloud storage, through cname or commondatastorage/bucket
    config.google_cloud_hosts = {
        'st0.diveboard.com' => 'st0.diveboard.com',
        'st1.diveboard.com' => 'st1.diveboard.com',
        'st2.diveboard.com' => 'st2.diveboard.com',
        'st3.diveboard.com' => 'st3.diveboard.com',
        'st4.diveboard.com' => 'st4.diveboard.com',
        'st5.diveboard.com' => 'st5.diveboard.com',
        'st6.diveboard.com' => 'st6.diveboard.com',
        'st7.diveboard.com' => 'st7.diveboard.com',
        'st8.diveboard.com' => 'st8.diveboard.com',
        'st9.diveboard.com' => 'st9.diveboard.com',
        'picts' => 'commondatastorage.googleapis.com/picts',
        'cache-pics' => 'commondatastorage.googleapis.com/cache-pics',       # 'cache-pics.diveboard.com',
        'cache-pics-orig' => 'commondatastorage.googleapis.com/cache-pics-orig',       # 'cache-pics-orig.diveboard.com',
        'cache-test-pics' => 'commondatastorage.googleapis.com/cache-test-pics',   #'cache-test-pics.diveboard.com'
        'cache-test-pics-orig' => 'commondatastorage.googleapis.com/cache-test-pics-orig'   #'cache-test-pics-orig.diveboard.com'
      }

    config.storage_plans = {
      :stor_10 => {:duration => 1.year, :quota => 10.gigabyte, :cost => 15, :title => '10Gb : $15.00USD - 1 year', :paypal_code => '10Gb'},
      :stor_50 => {:duration => 1.year, :quota => 50.gigabyte, :cost => 75, :title => '50Gb : $75.00USD - 1 year', :paypal_code => '50Gb'},
    }

    ## Configuration for assets
    config.paths['app/views'] << "app/assets/templates"

    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.prefix = '/assets/ppl'
    #config.assets.paths << Rails.root.join("app", "views", "templates")
    config.assets.compress = true
    config.assets.precompile << Proc.new do |path|
      if path =~ /\.(css|js)\z/ && path !~ /^_/ then
        full_path = Rails.application.assets.resolve(path)
        assets_paths = [ Rails.root.join('app', 'assets', 'javascripts'), Rails.root.join('app', 'assets', 'stylesheets') ]
        if assets_paths.include? full_path.dirname  then
          puts "including asset: " + full_path.to_path
          true
        else
          false
        end
      else
        false
      end
    end

    # Default is to allow debug, but should be overloaded in dedicated environment file
    config.assets.debug = true
    #config.assets.js_compressor = :uglifier
    config.assets.js_compressor = Uglifier.new(:output => { :comments => :none })
    config.asset_host = ->(source, request){
      protocol = request.env['HTTP_X_FORWARDED_SCHEME'] || request.protocol rescue "http://"
      HtmlHelper.find_lbroot_for(source).gsub(/\/$/,"").gsub(/^https?:\/\//, protocol)
    }

    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en, :fr, :es, :zh]
    config.i18n.fallbacks = false
    config.i18n.default_separator = " |#i18n#| "   # must be special so that it doesn't appear in keys
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*', '*.{rb,yml}').to_s]

    configure do
      config.map_og_locales = {en: :en_US, fr: :fr_FR, es: :es_ES, zh: :zh_CN}
      config.map_flag_locales = {en: :us, fr: :fr, es: :es, zh: :cn}
      config.map_untranslated_locales = {en: "English", fr: "Français", es: "Español", zh: "簡體中文"}
      config.map_disqus_locales = {en: :en, fr: :fr, es: :es_ES, zh: :zh}
      config.opened_locales = [:en, :fr, :es, :zh]
    end


    # IP spoofing protection is stupidly written and raises exception
    # when people use local proxies on their own computer
    config.action_dispatch.ip_spoofing_check = false

    ##use oink
    #config.middleware.use Oink::Middleware, :logger => Rails.logger
    config.middleware.use "FixHttpAcceptHeader"

    config.middleware.insert 0, Rack::UTF8Sanitizer
  end
end


## Ugly hack agains oddly formated mime type lookups (ie googlebot's mobile xhtml)
module Mime 
  class Type 
    def self.lookup(string) 
      LOOKUP[string.split(';').first] 
    end 
  end 
end

