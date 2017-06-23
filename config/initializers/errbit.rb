Airbrake.configure do |config|
  config.api_key = '60678888103f73a9ff1a58e88b425561'
  config.host    = 'diveboard-errbit.herokuapp.com'
  config.port    = 80
  config.secure  = config.port == 443
end