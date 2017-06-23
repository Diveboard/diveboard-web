#encoding: UTF-8
require 'nokogiri'

module GSearchHelper

  class Parser
    def initialize keywords, limit = 40
      @base_url = "http://www.google.com"
      @previous_url = "http://www.google.com"
      @keywords = keywords
      @limit = limit
      @next_query = "/search?q=#{CGI.escape @keywords}"
    end

    def urls limit = @limit
      gsearch limit if @urls.nil?
      return @urls
    end

    def next_urls limit = @limit
      gsearch limit
      return @urls
    end

    def position domain
      urls.each_with_index do |url, idx|
        return {:idx => idx+1, :url => url} if url.match /#{domain}/
      end
      return nil
    end

    def positions domain
      positions = []
      urls.each_with_index do |url, idx|
        positions.push({:idx => idx+1, :url => url}) if url.match /#{domain}/ rescue puts "Error with: #{url}"
      end
      return positions
    end


  private

    def gsearch limit=10
      return [] if @next_query.blank? || limit <= 0
      @urls = [] if @urls.nil?

      cmd = "curl -s -e '#{@previous_url}' -A 'Lynx/2.8.8dev.12 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/2.12.1' '#{@base_url}#{@next_query}'"
      google_search = `#{cmd}`
      parsed_xml = Nokogiri::HTML.parse(google_search, nil, 'ISO-8859-1')
      parsed_xml.xpath('//font[@color="green"]').each do |s|
        @urls.push s.content.to_s.gsub(/ - [0-9]*k$/, '')
      end

      next_url = nil
      parsed_xml.xpath('//a/strong').each do |s| next_url = s.parent['href'] if s.content.match /Next/ end

      @previous_url = "#{@base_url}#{@next_query}"
      @next_query = next_url

      sleep (0.5 + 3*Random.new.rand) if limit > 1
      gsearch(limit-1)
    end

  end
end

# Usage:
#   gs = GSearchHelper::Parser.new "dive in belize"
#   gs.position "diveboard.com"
#   gs.urls
