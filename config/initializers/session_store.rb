# Be sure to restart your server when you modify this file.

#DiveBoard::Application.config.session_store :cookie_store, :key => '_DiveBoard_session_v2'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
#DiveBoard::Application.config.session_store :active_record_store, domain: COOKIES_DOMAIN, key: '_session2_id'


DiveBoard::Application.config.session_store :active_record_store, domain: COOKIES_DOMAIN, key: "_session2_id_#{Rails.env}"
