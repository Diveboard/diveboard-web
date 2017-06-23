# Template Handler
require 'action_view'
require 'active_support'
require 'ejs'
require 'i18n-js'
require "execjs"


module ExecJS
  class ExternalRuntime < Runtime
    class Context < Runtime::Context
      def eval_with_protection source, *args
        eval_without_protection source.gsub(/[\u{2028}\u{2029}]/, "\\n"), *args
      end
      alias_method_chain :eval, :protection
    end
  end
end


class EJSHandler
  def supports_streaming?
    false
  end

  def handles_encoding?
    false
  end


  def self.call(template)
    new.call(template)
  end

  def call(template)
    #with Ruby parsing (useless for i18n)
    #"@output_buffer = output_buffer || ActionView::OutputBuffer.new;@output_buffer.safe_concat(eval ERB.new(EJS.evaluate(\"#{template.source}\", Hash[local_variables.collect { |v| [v, eval(v.to_s)] }])).src);"
    # without Ruby parsing
    "@output_buffer = output_buffer || ActionView::OutputBuffer.new;@output_buffer.safe_concat(EJSHandler.evaluate(\"#{escape_text(template.source)}\", Hash[local_variables.collect { |v| [v, eval(v.to_s)] }]));"
  end

  def escape_text(text)
    @@table_ ||= { "\r"=>"\\r", "\n"=>"\\n", "\t"=>"\\t", '"'=>'\\"', "\\"=>"\\\\" }
    text.gsub!(/[\r\n\t"\\]/) { |m| @@table_[m] }
    return text
  end

  def self.evaluate template, locals={}, options={}
    @@context ||= {}
    if @@context[I18n.locale].nil? then
      setup_variables = "I18n.translations = #{SimplesIdeias::I18n.translations.to_json};"
      setup_locale = "I18n.locale = '#{I18n.locale}';"
      @@context[I18n.locale] = ExecJS.compile(File.read(Rails.application.assets.resolve('i18n')) + setup_variables + setup_locale)
    end

    script = EJS.compile(template, options)
    @@context[I18n.locale].call(script, locals)
  end

end
