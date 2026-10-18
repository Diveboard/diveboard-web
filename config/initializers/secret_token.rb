# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
#
# Never commit the real value: this repository is public, and anyone who knows it can
# forge signed cookies (which Rails 3.2 loads with Marshal). Production reads it from the
# SECRET_TOKEN environment variable (diveboard_env on the server).
secret_token = ENV["SECRET_TOKEN"].to_s

if secret_token.length < 64
  if Rails.env.production?
    raise "SECRET_TOKEN is missing or shorter than 64 characters; refusing to start in production"
  end
  # Development/test only.
  secret_token = "development-only-secret-token-not-used-in-production-0123456789abcdef"
end

DiveBoard::Application.config.secret_token = secret_token
