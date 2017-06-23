class UpdateShopUrl < ActiveRecord::Migration
  def self.up
    Dive.all.each do |dive|
      begin
        s = dive.shop
        if s.nil? && dive.diveshop.nil? then
          next
        elsif s.nil? then
          dive.diveshop = nil
        else
          if s['url'].nil? || s['url'].length == 0 then
            s.url = nil
          elsif !s['url'].match(/^http:\/\//) then
            s['url'] = "http://"+s['url']
          end
          dive.diveshop = s.to_json
        end
        dive.save!
      rescue
      end
    end
  end

  def self.down
  end
end
