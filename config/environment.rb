# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
DiveBoard::Application.initialize!


require 'rubygems'
require 'active_support/all'

require 'koala'


class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class Formatter
  USE_HUMOROUS_SEVERITIES = true

  def call(severity, time, progname, message)
    direct_prg_line = ""
    stack_line = ""
    #if caller.at(5).match(/\/app\//) then
    #  direct_prg_line = caller.at(5).sub(%r{.*/},'').sub(%r{:in\s.*},'')  + " - "
    #end
    #the following block line may be time consuming, so only use it for intense debug
    #stack_line = "                           -"
    #caller.each do |line|
    #  if line.match /\/app\// then
    #    stack_line += '   Called by '+line.sub(%r{.*/},'').sub(%r{:in\s.*},'')
    #  end
    #end


    buffer = ""
    message.split("\n").each { |line|
      next if line == ""
      line.gsub!(/^Started ([A-Z]+) /, "\033[0;1;34m\\0\033[0m")
      line = "%s - %s - #%d - %s%s%s\n" % [
                                   Time.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
                                   severity,
                                   $$,
                                   direct_prg_line,
                                   line,
                                   stack_line,
                                   ]

      buffer << line
    }
    return buffer
  end
end

Rails.logger.formatter = Formatter.new

#module ActiveSupport
#  class BufferedLogger
#    def add(severity, message = nil, progname = nil, &block)
#      return if @level > severity rescue return
#      message = (message || (block && block.call) || progname).to_s
#
#      level = {
#        0 => "DEBUG",
#        1 => "INFO",
#        2 => "WARN",
#        3 => "ERROR",
#        4 => "FATAL"
#      }[severity] || "U"
#
#
#      direct_prg_line = ""
#      stack_line = ""
#      if caller.at(1).match(/\/app\//) then
#        direct_prg_line = caller.at(1).sub(%r{.*/},'').sub(%r{:in\s.*},'')  + " - "
#      end 
#      #the following block line may be time consuming, so only use it for intense debug
#      #stack_line = "                           -"
#      #caller.each do |line|
#      #  if line.match /\/app\// then
#      #    stack_line += '   Called by '+line.sub(%r{.*/},'').sub(%r{:in\s.*},'')
#      #  end
#      #end
#
#      message.split("\n").each { |line|
#        next if line == ""
#        line.gsub!(/^Started ([A-Z]+) /, "\033[0;1;34m\\0\033[0m")
#        line = "%s - %s - #%d - %s%s%s\n" % [
#                                     Time.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
#                                     level,
#                                     $$,
#                                     direct_prg_line,
#                                     line,
#                                     stack_line,
#                                     ]
#
#        buffer << line
#      }
#      auto_flush
#      message
#    end
#  end
#end
