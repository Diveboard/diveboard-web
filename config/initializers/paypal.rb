require 'paypal'

if Rails.env != 'production'
  Paypal.sandbox!
end

module Paypal
  module NVP
    class Request
      def post_with_debugger(method, params = {})
        Rails.logger.debug "PAYPAL endpoint: #{self.class.endpoint}"
        Rails.logger.debug "PAYPAL Request Method: #{method}"
        Rails.logger.debug "PAYPAL Request Params: #{params.to_query}"
        response = post_without_debugger(method, params)
        Rails.logger.debug "PAYPAL Reponse: #{response}"
        response
      end
      alias_method_chain :post, :debugger
    end
  end
end