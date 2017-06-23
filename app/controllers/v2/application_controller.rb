class V2::ApplicationController < ::ApplicationController
	layout "v2"
	before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :signup_popup_hidden
  @page = ""
end
