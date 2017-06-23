# encoding: UTF-8
require 'i18n'
require 'yaml'
require 'it'


module It
  def self.it(identifier, options = {})
    ActiveSupport::Notifications.instrument("translate.i18n") do
      @@parser ||= Parser.new("", "")
      options.stringify_keys!
      @@parser.string = I18n.t(identifier, locale: (options["locale"] || I18n.locale), default: options['default'], scope: options['scope'])
      @@parser.options = options
      return @@parser.process
    end
  end
  module Helper
    def it(identifier, options = {})
      ActiveSupport::Notifications.instrument("translate.i18n") do
        @@parser ||= Parser.new("", "")
        options.stringify_keys!
        @@parser.string = t(identifier, locale: (options["locale"] || I18n.locale), scope: options['scope'])
        @@parser.options = options
        a=@@parser.process
        #return ("‡"+a+"‡").html_safe
        return a
      end
    end
  end

  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current["i18n_runtime"] = value
    end

    def self.runtime
      Thread.current["i18n_runtime"] ||= 0
    end

    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end

    def translate(event)
      self.class.runtime += event.duration
    end
  end


  module Railties
    module ControllerRuntime
      extend ActiveSupport::Concern

    protected

      attr_internal :i18n_runtime_before_render
      attr_internal :i18n_runtime_during_render

      def cleanup_view_runtime
        self.i18n_runtime_before_render = It::LogSubscriber.reset_runtime
        runtime = super
        self.i18n_runtime_during_render = It::LogSubscriber.reset_runtime
        runtime - i18n_runtime_during_render
      end

      def append_info_to_payload(payload)
        super
        payload[:i18n_runtime] = (i18n_runtime_before_render || 0) +
                                 (i18n_runtime_during_render || 0) +
                                 It::LogSubscriber.reset_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, i18n_runtime = super, payload[:i18n_runtime]
          messages << ("I18n: %.1fms" % i18n_runtime) if i18n_runtime
          messages
        end
      end
    end
  end
end

It::LogSubscriber.attach_to :i18n

ActiveSupport.on_load(:action_controller) do
  include It::Railties::ControllerRuntime
end

module I18n
  class << self
    alias :handle_exception_old :handle_exception
    def handle_exception(handling, result, locale, key, options)

      if key.is_a? Symbol then
        stupidly_called = backend.translate(locale, key.to_s.gsub(".", I18n.default_separator).to_sym, options) rescue nil
        Rails.logger.debug("It seems it used dots when calling the parameter") and return stupidly_called unless stupidly_called.nil?
      end

      Rails.logger.warn("Missing key '#{key}' for locale '#{locale}' with #{options}")

      #Logging missing keys in file
      begin
        missing = {}
        backend = config.backend
        filename = 'log/missing_i18n.yml'
        missing = YAML.load(File.open(filename)) rescue {}
        missing ||= {}

        missing_locales = [locale]

        self.available_locales.each do |l|
          begin
            backend.translate(l, key, options)
          rescue
            missing_locales.push l
          end
        end

        Rails.logger.debug "Other missing locales: #{missing_locales}"

        scope = options[:scope] rescue []
        scope ||= []

        has_changed = false
        missing_locales.uniq.each do |l|
          missing[l] ||= {}
          h = missing[l]
          l_scope = scope.dup
          while !l_scope.empty? do
            k = l_scope.shift
            h[k] ||= {}
            h=h[k]
          end

          if !h.include?(key) then
            h[key] = ""
            h[key] = key if l == default_locale
            has_changed = true
          end
        end

        if has_changed then
          File.open(filename, 'w') do |f|
            f.flock(File::LOCK_EX)
            f.write YAML.dump(missing)
          end
        end
      rescue Exception => e
        Rails.logger.warn $!.class.name
        Rails.logger.warn $!.message
      end

      # Fallback : Getting default translation, the default being the key text
      options = options.dup
      if options[:default].nil? then
        options[:default] = key
      elsif options[:default].is_a? Array then
        options[:default].push key
      else
        options[:default] =  [options[:default], key]
      end
      return backend.translate(default_locale, key, options) rescue return key
    end
  end
end
