require 'money'

eu_bank = EuCentralBank.new
Money.default_bank = eu_bank
Money.use_i18n = false  #because: 
#irb(main):020:0> I18n.t "separator", :scope =>[:number, :format]
#=> "."
#irb(main):021:0> I18n.t "separator", :scope =>"number.format"
#=> "separator"

eu_bank.update_rates("tmp/exchange_rates.xml") rescue eu_bank.update_rates("config/default_exchange_rates.xml")

class Money
  class Currency
    def self.available
      currencies = self.table.map do |a,u| u end .reject do |currency| currency[:symbol].nil? || currency[:symbol].match(' or ') rescue true end
      convertible_currencies = Money.default_bank.rates.keys.map do |s| s.split('_TO_') end .flatten.uniq
      currencies.reject! do |currency| !convertible_currencies.include?(currency[:iso_code]) end
    end

    def self.supported
    	supported_code = [
    		"AUD",
    		"CAD",
    		"CZK",
    		"DKK",
    		"EUR",
    		"HKD",
    		"HUF",
    		"JPY",
    		"NOK",
    		"NZD",
    		"PLN",
    		"GBP",
    		"SGD",
    		"SEK",
    		"CHF",
    		"USD"
    	]
    	currencies = self.table.map do |a,u| u end .reject do |currency| currency[:symbol].nil? || currency[:symbol].match(' or ') rescue true end
      	convertible_currencies = Money.default_bank.rates.keys.map do |s| s.split('_TO_') end .flatten.uniq
      	currencies.reject! do |currency| !convertible_currencies.include?(currency[:iso_code]) end

      	currencies.reject! do |currency|
      		!supported_code.include?(currency[:iso_code])
      	end
    end
  end
end