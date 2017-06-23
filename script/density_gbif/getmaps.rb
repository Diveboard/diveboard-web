#!/usr/bin/ruby
require 'open-uri'
require 'net/http'

f = File.open("gbif.lst", "r")

o1 = File.open("curl_#{ARGV[0]}", "w")
o2 = File.open("list_#{ARGV[0]}", "w")
rejected_file = File.open("reject_#{ARGV[0]}", "w")

skip_remaining = nil

trap "SIGINT", proc{ skip_remaining = 'interrupted' }

retry_count = 0

f.each { |line|
    gbif_id = line.to_i

    if !(gbif_id.modulo(7) == ARGV[0].to_i) then 
      next
    end

    start_index = 0
    continue_request = true
    map = {}

    o1.write "? 1\n"
    o1.flush

    while continue_request do

      continue_request = false

      o1.write "? 2\n"
      o1.flush

      if !skip_remaining.nil? then
        rejected_file.write "#{gbif_id} - #{skip_remaining}\n"
        next
      end

      url = "http://data.gbif.org/ws/rest/occurrence/list?startindex=#{start_index}&coordinatestatus=true&taxonconceptkey="
      url += gbif_id.to_s

      o1.write "? 3\n"
      o1.flush

      begin
        document = Net::HTTP.get(URI.parse(url))
      rescue Exception
        redo
      end
      
      o1.write "? 4\n"
      o1.flush

      o1.write "= #{gbif_id} #{start_index}\n"
      o1.write "! #{url}\n"
      o1.write(document)
      o1.write " \n"

      o1.write "? 5\n"
      o1.flush

      if document.scan(/gbif:exceptionReport/).count > 0 then
        o1.write "? 6\n"
        o1.flush

        if retry_count < 5 then 
          retry_count += 1
          redo
        else
          rejected_file.write "#{gbif_id} - Too many errors\n"
          next
        end
      end

      o1.write "? 7\n"
      o1.flush

      if document.scan(/503 Service Temporarily Unavailable/).count > 0  || document.scan(/DOCTYPE HTML PUBLIC/).count > 0 then
        o1.write "? Going to sleep\n"
        o1.flush
        sleep 4*3600
        o1.write "? Finished sleeping, feeling better\n"
	if retry_count < 10 then
          retry_count += 1
          redo
        else
          rejected_file.write "#{gbif_id} - Too many errors\n"
          redo
        end
      end

      retry_count = 0

      o1.write "? 8\n"
      o1.flush

      o2.write "\n= #{gbif_id} #{start_index}\n"
      o2.write "! #{url}\n"

      document.scan(/gbif:summary.*totalReturned="([0-9]*)"/).each{ |num|
        o2.write "@ #{gbif_id} #{num[0]}\n"
      }

      document.scan(/gbif:summary.*next="([0-9]*)"/).each{ |num|
        start_index = num[0]
        continue_request = true
      }

      document.scan(/<to:decimalLatitude>([^<]*)<\/to:decimalLatitude>[ \n\t\r]*<to:decimalLongitude>([^<]*)<\/to:decimalLongitude>/).each { |lat,lng|
        o2.write "# #{gbif_id} #{lat} #{lng}\n"
      }

      o1.write "? 9\n"
      o1.flush

     end
}

