DiveBoard::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  ## SCU.BZ Routing
  constraints :domain => "scu.bz" do
    root :to => redirect("https://www.diveboard.com") 
    match '/:dive_id' => 'diveinfo#read_tiny', :dive_id => /[0-9]+/
    match '/p/:picture_id' =>  'diveinfo#read_tiny', :picture_id => /[0-9]+/
    match '/u/:vanity' => 'diveinfo#read_tiny_home', :vanity => /[A-Za-z\.0-9\-\_]+/
    match '/:hash' => 'diveinfo#read_tiny_hash', :hash => /[A-Za-z0-9]+/
    match '/' => redirect("https://www.diveboard.com") 
  end
  ##END SCU.BZ

  ## All but scu.bz domain

  root :to => 'v2/homepage#index'
  match "/lnk/:hash" => 'diveinfo#read_tiny_hash', :hash => /[A-Za-z0-9]+/

  match '/log' => 'home#index'
  match '/login/user_login' => 'login#user_login'
  match '/logout' => 'login#delete'
  match '/login/callback' => 'login#callback'
  match '/login/register' => 'login#register_get', :via => :get
  match '/login/register' => 'login#register_post', :via => :post
  match '/login/forgot' => 'home#forgot' #forgot password
  match '/login/forgot/:email/:token' => 'home#pwd_reset', :email => /[a-z0-9._%+-@]*/ #create new pwd after getting reset email
  match '/login/pwd_reset' => 'login#pwd_reset'
  match '/login/forgot_email' => 'home#forgot_email'
  match '/login/fb_login/:perms' => 'login#fb_login'
  match '/login/fb_vanity' => 'home#fb_vanity'
  match '/login/register_pro' => 'commercial_shop#register_shop', save_origin_url: true
  match '/login/register_pro/:step' => 'commercial_shop#register_shop', save_origin_url: true
  match '/login/widget/:partner' => 'login#widget_login'

  match '/home' => 'connected_home#main'



  ######## ADMIN  ## those check user is admin otherwises 404
  ##Enables the snapshot tool to connect to alex's logbook using a secret token
  #match '/admin/test_wizard/:token' => 'admin#test_wizard', :constraints =>{:subdomain =>"stage"}
  #match '/admin/test_wizard/:token' => 'admin#test_wizard', :constraints =>{:subdomain =>"dev"}
  match '/admin' => 'admin#dashboard'
  match '/admin/users' => 'admin#users'
  match '/admin/users/:user_id' => 'admin#user_view', :user_id => /[0-9]+/
  match '/admin/users/:user_id/kill' => 'admin#user_kill', :user_id => /[0-9]+/, :constraints =>{:subdomain =>"dev"}
  match '/admin/users/:user_id/kill' => 'admin#user_kill', :user_id => /[0-9]+/, :constraints =>{:subdomain =>"stage"}
  match '/admin/spots' => 'admin#spot'
  match '/admin/uncluster_spot' => 'admin#uncluster_spot'
  match '/admin/uncluster_spot/:id' => 'admin#uncluster_spot', :id => /[0-9]+/
  match '/admin/uncluster_spot/merge' => 'admin#uncluster_spot_merge'
  match '/admin/uncluster_spot/distinct' => 'admin#uncluster_spot_distinct'
  match '/admin/uncluster_spot/rebuild' => 'admin#uncluster_spot_init'
  match '/admin/check_background_job/:id' => 'admin#check_background_job'
  match '/admin/spot-edit/:id' => 'admin#spot_edit', :id => /[0-9]*/
  match '/admin/spot-edit' => 'admin#spot_edit', :id => /[0-9]*/
  #match '/admin/moderate_spot/:id' => 'admin#spot_moderate', :id => /[0-9]+/
  #match '/admin/moderate_spot' => 'admin#spot_moderate'
  match '/admin/mod_spot/:spot' => 'admin#spot_moderate2', :spot => /[0-9]+/
  match '/admin/mod_spot' => 'admin#spot_moderate2'
  match '/admin/mod_location/:id' => 'admin#location_moderate', :id => /[a-z]+/
  match '/admin/mod_location' => 'admin#location_moderate'
  match '/admin/mod_history' => 'admin#mod_history'
  match '/admin/save_moderate_spot' => 'admin#save_spot_moderate'
  match '/admin/save-spot' => 'admin#save_spot'
  match '/admin/shops' => 'admin#shops_dash'
  match '/admin/shops_edit' => 'admin#shops_save'
  match '/admin/shops/:id' => 'admin#shops', :id => /[0-9]+/, :via => "get"
  match '/admin/shops/new' => 'admin#shops', :via => "get"
  match '/admin/dives' => 'admin#dives'
  match '/admin/pictures/mark_great' => 'admin#mark_pictures_great'
  match '/admin/pictures' => 'admin#pictures'
  match '/admin/species/:species_id' => 'admin#species', :species_id => /[cs]-[0-9]*/
  match '/admin/species/:category' => 'admin#species', :category => /[{a-z}|{\%20}]*/
  match '/admin/species' => 'admin#species'
  match '/admin/monitoring' => 'admin#monitoring'
  match '/admin/reviews' => 'admin#reviews'
  match '/admin/orders' => 'admin#orders'
  match '/admin/orders/:basket_id' => 'admin#order_detail'
  match '/admin/testfbusergen' => 'admin#testfbusergen', :constraints =>{:subdomain =>"stage"}
  match '/admin/testfbusergen' => 'admin#testfbusergen', :constraints =>{:subdomain =>"dev"}
  match '/admin/testfbusergen/:perms' => 'admin#testfbusergen', :constraints =>{:subdomain =>"stage"}
  match '/admin/testfbusergen/:perms' => 'admin#testfbusergen', :constraints =>{:subdomain =>"dev"}
  match '/admin/testfbuserdel/:user_id' => 'admin#testfbuserdel', :constraints =>{:subdomain =>"stage"}
  match '/admin/testfbuserdel/:user_id' => 'admin#testfbuserdel', :constraints =>{:subdomain =>"dev"}
  match '/admin/testshopgen' => 'admin#testshopgen', :constraints =>{:subdomain =>"stage"}
  match '/admin/testshopgen' => 'admin#testshopgen', :constraints =>{:subdomain =>"dev"}
  match '/admin/testshopvalid' => 'admin#testshopvalid', :constraints =>{:subdomain =>"stage"}
  match '/admin/testshopvalid' => 'admin#testshopvalid', :constraints =>{:subdomain =>"dev"}
  match '/admin/filter_log' => 'admin#logf'
  match '/admin/blogposts' => 'admin#blogposts'
  match '/admin/blogposts/approve' => 'admin#blogposts_moderate', :moderate_action => :approve, :via => "post"
  match '/admin/blogposts/dismiss' => 'admin#blogposts_moderate', :moderate_action => :dismiss, :via => "post"
  match '/admin/newsletter' => 'admin#newsletter'
  match '/admin/newsletter_send' => 'admin#newsletter_send'
  match '/admin/charts' => 'admin#charts'
  match '/admin/dashboard_stats' => 'admin#dashboard_stats'

  match '/admin/email_test' => 'admin#email_test' ##test to preview a like email


  ######## /ADMIN
  #match '/sitemap' => 'home#sitemap'
  match '/fbpage' => 'facebook_app#read'

  ## SETTINGS
  match '/settings' => 'settings#read'
  match '/settings/:id' => 'settings#read', :id => /[0-9]*/
  match '/settings/orders' => 'settings#orders', :id => 3
  match '/settings/orders/:basket_id' => 'settings#orders', :id => 3
  match '/settings/messages' => 'settings#orders', :id => 4
  match '/settings/messages/:message_id' => 'settings#orders', :id => 4
  match '/settings/update' => 'settings#update'
  match '/settings/uploadpict' => 'settings#uploadpict'

  ## about pages
  ## layouts for the blog
  match '/about' => 'staticpages#about'
  match '/about/tos' => 'staticpages#tos'
  match '/about/test_computer' => 'staticpages#test_computer'
  match '/about/privacy' => 'staticpages#privacy'
  match '/about/tour' => 'staticpages#tour'
  match '/about/tour/:what' => 'staticpages#tour'
  match '/about/import' => 'staticpages#import'
  match '/about/import/:id' => 'staticpages#import'
  match '/about/:id' => 'staticpages#about'


  ## Explore
  match '/search' => 'search#search'
  match '/explore' => 'search#explore'
  #match '/explore/gallery' => 'pictures#picture_browser'
  match '/assets/explore/:level/:asset_name' => 'search#explore_missing_asset', :level => /[0-9]*/, :asset_name => /[0-9]*_[0-9]*.data.json/

  ## API
  ##PUBLIC API START
  match '/api/login_fb' => 'api#login_fb'
  match '/api/login_email' => 'api#login_email'
  match '/api/update_contact_email' => 'api#update_contact_email'
  match '/api/reset_password' => 'api#reset_password'
  match '/api/movescount_acces' => 'api#movescount'
  ### deprecated 2014-01-10 ### match '/api/list_user_dives' => 'api#list_user_dives'
  ### deprecated 2014-01-10 ### match '/api/list_dive_details' => 'api#list_dive_details'
  ### deprecated 2014-01-10 ### match '/api/update_spot' => 'api#udpate_spot'
  ### deprecated 2014-01-10 ### match '/api/update_dive' => 'api#udpate_dive'
  match '/api/register_email' => 'api#register_email'
  match '/api/register_vanity_url' => 'api#register_vanity_url'
  ### deprecated 2014-01-10 ### match '/api/upload_profile' => 'api#upload_profile'
  match '/api/check_mobile_update' => 'api#check_mobile_update'
  ##PUBLIC API END

  match '/api/ping' => 'application#ping'
  match '/api/check_tagid' => 'tag#check_status'
  match '/api/register_user' => 'login#register_user'
  match '/api/spotinfo' => 'spotinfo#read'
  match '/api/spotupdate' => 'spotinfo#create'
  match '/api/user_dives_on_spot' => 'spotinfo#user_dives_on_spot'
  match '/api/udcfupload' => 'diveinfo#udcfupload'
  match '/api/divefromtmp' => 'diveinfo#divefromtmp'
  match '/api/profilefromtmp' => 'diveinfo#profilefromtmp'
  match '/api/movescount' => 'diveinfo#movescount'
  match '/api/computerupload' => 'diveinfo#computerupload'
  match '/api/update_logbook' => 'logbook#update_logbook_settings'
  match '/api/fishsearch' => 'fishinfo#fishsearch'
  match '/api/fishsearch_extended' => 'fishinfo#fishsearch_extended', :via => :post
  match '/api/divewizard/:vanity_url/:dive_id' => 'diveinfo#wizard',:vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive_id => /[0-9]*/
  match '/api/bulklisting' => 'diveinfo#bulk_listing'
  match '/api/setprivacy/:dive_id' => 'diveinfo#setprivacy', :dive_id => /[0-9]*/
  match '/api/put_logs' => 'diveinfo#put_logs'
  match '/api/js_logs' => 'application#put_logs'
  match '/api/get_videothumb' => 'diveinfo#get_videothumb'
  match '/api/fbvideo_proxy' => 'pictures#fbvideo_proxy'
  match '/api/export_dives' => 'diveinfo#export_dives'
  match '/api/delete_dives' => 'diveinfo#delete_dives'
  match '/api/print_dives' => 'diveinfo#print_dives'
  match '/api/update_privacy_dives' => 'diveinfo#update_privacy_dives'
  match '/api/fb_pushtimeline' => 'diveinfo#fb_pushtimeline'
  match '/api/notify_event' => 'diveinfo#notify_event', :via => :post
  match '/api/notify_command' => 'shop_pages#command', :via => :get
  match '/api/invite_buddy' => 'api#invite_buddy'
  match '/api/search_spot_coord' => 'search#search_spot_coord'
  match '/api/search_spot_text' => 'search#search_spot_text'
  match '/api/search_region_text' => 'search#search_region_text'
  match '/api/search_shop_text' => 'search#search_shop_text'
  match '/api/search_diver_coord' => 'search#search_diver_coord'
  match '/api/search_diver_text' => 'search#search_diver_text'
  match '/api/search_diver_spot' => 'search#search_diver_spot'
  match '/api/explore/all' => 'search#explore_all'
  match '/api/explore/detail' => 'search#get_full_detail'
  ##    match '/api/search_any' => 'search#search_any'
  match '/api/fishmap' => 'search#fishmap'
  match '/api/search_spot' => 'admin#spot_search'
  match '/api/dedupe_spot' => 'admin#spot_dedupe'
  match '/api/uploaded_profile' => 'admin#uploaded_profile'
  match '/api/nolog_search' => 'home#search'
  match '/api/select_fb_vanity' => 'login#select_fb_vanity'
  match '/api/check_vanity_url' => 'settings#check_vanity_url'
  match '/api/check_email' => 'settings#check_email'
  match '/api/stats' => 'home#stats'
  match '/api/search/country' => 'spotinfo#searchcountry'
  match '/api/search/location' => 'spotinfo#searchlocation'
  match '/api/search/region' => 'spotinfo#searchregion'
  match '/api/search/spot' => 'api#searchspot'
  match '/api/search/shop' => 'spotinfo#searchshop'
  match '/api/search/user' => 'spotinfo#searchuser'
  match '/api/user/checkgravatar' => 'diveinfo#checkgravatar'
  match '/api/pictures/picasa_share' => 'diveinfo#picasa_share'
  match '/api/picture/upload' => 'pictures#write'
  match '/api/picture/get/:shaken_id' => 'pictures#redirect' , :format => "medium"
  match '/api/picture/get/:shaken_id/:format' => 'pictures#redirect'
  match '/api/picture/download/:shaken_id' => 'pictures#download'
  match '/api/paypal/start_basket' => 'basket#paypal_start'
  match '/api/paypal/start' => 'payments#start'
  match '/api/paypal/check' => 'payments#check'
  match '/api/paypal/return' => 'payments#return'
  match '/api/paypal/permission_start' => 'payments#permission_start'
  match '/api/paypal/permission_return' => 'payments#permission_return'
  match '/api/paypal/subscription_return' => 'payments#subscription_return'
  match '/api/paypal/basket_return' => 'payments#basket_return'
  match '/api/paypal/basket_ipn' => 'payments#basket_ipn'
  match '/api/shop/claim_explain' => 'shop_pages#post_claim_uservoice'
  match '/api/shop/claim_mail' => 'shop_pages#mail_claim_shop'
  match '/api/shop/claim_valid' => 'shop_pages#confirm_claim_user'
  match '/api/report_review' => 'shop_pages#report_review'
  match '/api/report_content' => 'api#report_content', :via => :post
  match '/api/reply_review' => 'api#shop_reply_review'
  match '/api/wiki/get' => 'wiki#get'
  match '/api/wiki/update' => 'wiki#update'
  match '/api/update_fbtoken' => 'login#update_fbtoken', :via => :post
  match '/api/add_missing_species' => 'fishinfo#add_missing_species', :via => :post
  match '/api/partial/header' => 'home#render_partial_header'
  match '/api/version/:component' => 'api#versions'

  match '/api/widget_update' => 'api#widget_update', :via => :post


  match '/api/redirect/logbook' => 'logbook#cool_logbook'
  match '/api/js_view/:dir/:js.mv.js' => 'application#serve_js_view', :dir => /[a-zA-Z0-9\/_-]*/, :js => /[a-zA-Z0-9_.-]*/

  ## API with complete framework
  match '/api/user/gear' => 'api#user_gear_update', :via => :post
  match '/api/user/gear' => 'api#user_gear_read', :via => :get
  match '/api/dive/update' => 'api#dive_update', :via => :post
  match '/api/user/following' => 'api#user_read_follow', :via => :get
  match '/api/user/following' => 'api#user_add_follow', :via => :post
  match '/api/bulk_proxy' => 'api#bulk_proxy'

  #Basket partials
  match '/api/basket/view_html' => 'basket#view'

  #Basket API
  match '/api/basket/get' => 'basket#get_basket'
  match '/api/basket/add' => 'basket#add_to_basket'
  match '/api/basket/reset' => 'basket#reset_basket'
  match '/api/basket/update' => 'basket#update_in_basket'
  match '/api/basket/remove' => 'basket#remove_from_basket'

  match '/api/basket/manage/confirm' => 'basket#manage_confirm'
  match '/api/basket/manage/ask_detail' => 'basket#manage_ask_detail'
  match '/api/basket/manage/reject' => 'basket#manage_reject'
  match '/api/basket/manage/deliver' => 'basket#manage_deliver'

  ## Dive Signature API
  match '/api/care/sign_dives' => 'diveinfo#sign_dives'



  match '/api/templates/:template_name' => 'api#templates'


  ## API V2
  match '/api/V2/:stuff' => 'api#api_v2_options', :via => [:options], :stuff => /.*/
  match '/api/V2/user/new' => 'api#api_v2_new', :via => [:get], :type => :user
  match '/api/V2/user/:id' => 'api#api_v2', :via => [:get, :post], :type => :user
  match '/api/V2/user' => 'api#api_v2', :via => [:get, :post, :put], :type => :user
  match '/api/v2/treasurehunt' => 'api#treasure_hunt'
  match '/api/v2/movescount' => 'api#movescount_access'
  match '/api/v2/movescount_dives' => 'api#movescount_dives', :via => :post
  match '/api/V2/dive/new' => 'api#api_v2_new', :via => :get, :type => :dive
  match '/api/V2/dive/:id' => 'api#api_v2', :via => [:get, :post], :type => :dive
  match '/api/V2/dive/:id' => 'api#api_v2_delete', :via => :delete, :type => :dive
  match '/api/V2/dive' => 'api#api_v2_delete', :via => :delete, :type => :dive
  match '/api/V2/dive' => 'api#api_v2', :via => [:get, :post, :put], :type => :dive
  match '/api/V2/spot/new' => 'api#api_v2_new', :via => [:get], :type => :spot
  match '/api/V2/spot/:id' => 'api#api_v2', :via => [:get, :post], :type => :spot
  match '/api/V2/spot' => 'api#api_v2', :via => [:get, :post, :put], :type => :spot
  match '/api/V2/shop/new' => 'api#api_v2_new', :via => [:get], :type => :shop
  match '/api/V2/shop/:id' => 'api#api_v2', :via => [:get, :post], :type => :shop
  match '/api/V2/shop' => 'api#api_v2', :via => [:get, :post, :put], :type => :shop
  match '/api/V2/review/new' => 'api#api_v2_new', :via => [:get], :type => :review
  match '/api/V2/review/:id' => 'api#api_v2', :via => [:get, :post], :type => :review
  match '/api/V2/review/:id' => 'api#api_v2_delete', :via => [:delete], :type => :review
  match '/api/V2/review' => 'api#api_v2', :via => [:get, :post, :put], :type => :review

  match '/api/V2/review/:id/vote' => 'api#review_vote_read', :via => :get, :type => :internal_message
  match '/api/V2/review/:id/vote' => 'api#review_vote_create_or_update', :via => [:post, :put], :type => :internal_message
  match '/api/V2/review/:id/vote' => 'api#review_vote_delete', :via => :delete, :type => :internal_message

  match '/api/V2/notif/new' => 'api#api_v2_new', :via => [:get], :type => :notification
  match '/api/V2/notif/:id' => 'api#api_v2', :via => [:get, :post], :type => :notification
  match '/api/V2/notif/:id' => 'api#api_v2_delete', :via => [:delete], :type => :notification
  match '/api/V2/notif' => 'api#api_v2', :via => [:get, :post, :put], :type => :notification
  match '/api/V2/advertisement/new' => 'api#api_v2_new', :via => [:get], :type => :advertisement
  match '/api/V2/advertisement/:id' => 'api#api_v2', :via => [:get, :post], :type => :advertisement
  match '/api/V2/advertisement/:id' => 'api#api_v2_delete', :via => [:delete], :type => :advertisement
  match '/api/V2/advertisement' => 'api#api_v2', :via => [:get, :post, :put], :type => :advertisement
  match '/api/V2/good/new' => 'api#api_v2_new', :via => [:get], :type => :good_to_sell
  match '/api/V2/good/:id' => 'api#api_v2', :via => [:get, :post], :type => :good_to_sell
  match '/api/V2/good/:id' => 'api#api_v2_delete', :via => [:delete], :type => :good_to_sell
  match '/api/V2/good' => 'api#api_v2', :via => [:get, :post, :put], :type => :good_to_sell
  match '/api/V2/country' => 'api#api_v2', :via => [:get, :post], :type => :country
  match '/api/V2/country/:id' => 'api#api_v2', :via => [:get, :post], :type => :country
  match '/api/V2/picture/new' => 'api#api_v2_new', :via => [:get], :type => :picture
  match '/api/V2/picture/:id' => 'api#api_v2', :via => [:get, :post], :type => :picture
  match '/api/V2/picture/:id' => 'api#api_v2_delete', :via => [:delete], :type => :picture
  match '/api/V2/picture' => 'api#api_v2', :via => [:get, :post, :put], :type => :picture
  match '/api/V2/message/new' => 'api#api_v2_new', :via => :get, :type => :internal_message
  match '/api/V2/message/:id' => 'api#api_v2', :via => [:get, :post], :type => :internal_message
  match '/api/V2/message/:id' => 'api#api_v2_delete', :via => :delete, :type => :internal_message
  match '/api/V2/message' => 'api#api_v2_delete', :via => :delete, :type => :internal_message
  match '/api/V2/message' => 'api#api_v2', :via => [:get, :post, :put], :type => :internal_message
  match '/api/V2/membership/:id' => 'api#api_v2', :via => [:get, :post], :type => :membership
  match '/api/V2/membership/:id' => 'api#api_v2_delete', :via => :delete, :type => :membership
  match '/api/V2/membership' => 'api#api_v2_delete', :via => :delete, :type => :membership
  match '/api/V2/membership' => 'api#api_v2', :via => [:get, :post, :put], :type => :membership
  match '/api/V2/search/shop' => 'api#api_v2_search', :via => [:get, :post], :type => :shop
  match '/api/V2/search/review' => 'api#api_v2_search', :via => [:get, :post], :type => :review
  match '/api/V2/search/message' => 'api#api_v2_search', :via => [:get, :post], :type => :internal_message
  match '/api/V2/search/basket' => 'api#api_v2_search', :via => [:get, :post], :type => :basket
  match '/api/V2/search/shop_customer' => 'api#api_v2_search', :via => [:get, :post], :type => :shop_customer
  match '/api/V2/contest' => 'api#contest', :via => [:post]

  match '/api/widget/shop_medium/:shaken_id' => 'shop_widgets#medium'
  match '/api/widget/shop_reviews/:shaken_id' => 'shop_widgets#large'

  match '/api/v2/newsletter_subscribe/:email' => 'api#api_v2_newsletter', :via => [:get, :post], :email => /[a-z0-9._%+-@]*/

  ## Dedicated pages (spots, fish...)
  match '/explore/divers/:vanity' => 'search#explore', :vanity => /[A-Za-z\.0-9\-\_]*/
  match '/explore/dives/:dive_id' => 'search#explore'
  match '/explore/spots/zone/:region_blob' => 'search#explore'
  match '/explore/spots/zone' => 'search#explore'
  match '/explore/spots/:country_blob' => 'search#explore'
  match '/explore/spots/:country_blob/:location_blob' => 'search#explore'
  match '/explore/spots/:country_blob/:location_blob/:spot_blob' => 'search#explore'
  match '/explore/spots' => 'search#explore'
  match '/explore/shops/:shop_vanity' => 'search#explore'

  ##redirects from previous urls
  match '/pages/spots/zone/:region' => 'search#spotredirect'
  match '/pages/spots/zone' => 'search#spotredirect'
  match '/pages/spots/:country' => 'search#spotredirect'
  match '/pages/spots/:country/:location' => 'search#spotredirect'
  match '/pages/spots/:country/:location/:name' => 'search#spotredirect'
  #match '/pages/spots' => 'spotinfo#home_spots'
  match '/pages/species/:name' => 'fishinfo#species_page'

  ##da blog
  match '/community' => 'blog#home', :content => :home
  match '/community/contest' => 'v2/homepage#suunto'
  match '/community/feed' => 'blog#feed'
  match '/community/feed/:vanity_url' => 'blog#feed', :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/community/new' => 'blog#home', :content => :edit
  match '/community/update' => 'blog#update', :via => :post
  match '/community/delete' => 'blog#delete', :via => :post
  match '/community/edit/:post_id' => 'blog#home', :content => :edit, :post_id => /[a-zA-Z0-9]+/
  match '/community/edit/:post_id/:wiki_id' => 'blog#home', :content => :edit, :post_id => /[a-zA-Z0-9]+/, :wiki_id => /[a-zA-Z0-9]+/

  match '/community/newsletter' => 'blog#newsletter'
  match '/community/newsletter/unsuscribe' => 'blog#newsletter_unsuscribe'
  match '/community/newsletter/:id' => 'blog#newsletter', :id => /[0-9]+/

  match '/community/:category/:year/:month/:title' => 'blog#home', :content => :post, :category => /[A-Za-z\.0-9\-\_]*/, :year=> /[0-9]+/, :month=> /[0-9]+/
  match '/community/:year/:month' => 'blog#home', :content => :month, :year=> /[0-9]+/, :month=> /[0-9]+/
  match '/community/:year' => 'blog#home', :content => :year, :year=> /[0-9]+/, :month=> /[0-9]+/
  match '/community/:category/:year/:month' => 'blog#home', :content => :month_category, :year=> /[0-9]+/, :month=> /[0-9]+/, :category => /[A-Za-z\.0-9\-\_]*/
  match '/community/:category/:year' => 'blog#home', :content => :year_category, :year=> /[0-9]+/, :month=> /[0-9]+/, :category => /[A-Za-z\.0-9\-\_]*/
  match '/community/:category' => 'blog#home', :content => :category, :category => /[A-Za-z\.0-9\-\_]*/

  match '/tag/:shaken_id' => 'tag#redirect'

  match '/pro' => 'commercial_shop#index'
  # match '/pro/:vanity_url' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :view
  # match '/pro/:vanity_url/form_review' => 'logbook#get_form_review', :vanity_url => /[A-Za-z\.0-9\-\_]*/
  # match '/pro/:vanity_url/edit' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit
  # match '/pro/:vanity_url/edit/:realm' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit
  # match '/pro/:vanity_url/care' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :realm => 'care'
  # match '/pro/:vanity_url/care/basket/:basket_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :realm => 'care'
  # match '/pro/:vanity_url/care/message/:message_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :realm => 'care'
  # match '/pro/:vanity_url/care/customer/:customer_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :realm => 'care'
  # match '/pro/:vanity_url/partial/care' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :partial => 'care'
  # match '/pro/:vanity_url/partial/care/basket/:basket_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :partial => 'care'
  # match '/pro/:vanity_url/partial/care/message/:message_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :partial => 'care'
  # match '/pro/:vanity_url/partial/care/customer/:customer_id' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :edit, :partial => 'care'
  # match '/pro/:vanity_url/:realm' => 'shop_pages#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :view
  match '/testnewshop' => 'shop_pages#test_new_shop'

  match '/user_images/:image_id' => 'home#nouserpic'


  #SHORT LINKS
  match '/l/bulk' => 'home#redirect_bulk'




  constraints Rails.env != "production" do
      scope module: 'v2' do   
          match '/index' => 'homepage#index'
          match '/pro/test/area' => 'test_area_pages#index' 
          match '/pro/checkout' => 'checkout#index'
          match '/pro/payment_success/:vanity_url' => 'checkout#success', :vanity_url => /[A-Za-z\.0-9\-\_\%\+]*/
          ##resources :shop_pages
          match '/pro/:vanity_url' => 'shop_pages#index', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/edit' => 'shop_pages#edit', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/edit/:category' => 'shop_pages#edit', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :category => /[A-Za-z]*/
          match '/pro/:vanity_url/care/message/:message_id' => 'shop_pages#message', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/care/basket/:basket_id' => 'shop_pages#basket', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/buy' => 'shop_pages#buy_a_product', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/share' => 'shop_pages#share_to_friend', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :via => :post
          match '/pro/:vanity_url/review' => 'shop_pages#review', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/pro/:vanity_url/profile' => 'shop_pages#profile', :vanity_url => /[A-Za-z\.0-9\-\_]*/
          match '/area/:country' => 'area_pages#destination', :country => /.*-G[a-zA-Z0-9]+/
          match '/area/:country/:region' => 'area_pages#destination', :country => /.*-G[a-zA-Z0-9]+/ , :region => /[A-Za-z\.0-9\-\_]*/           
          match '/area/:country/:region/:place' => 'area_pages#destination', :country => /.*-G[a-zA-Z0-9]+/ , :region => /[A-Za-z\.0-9\-\_]*/, :place => /[A-Za-z\.0-9\-\_]*/
          match '/area/:country/:vanity_url' => 'area_pages#index_with_id', :country => /[0-9\-\_]*/, :vanity_url => /[A-Za-z\.0-9\-\_\%\+]*/
          match '/area/:country/:vanity_url' => 'area_pages#index', :country => /[A-Za-z\.0-9\-\_\%\+]*/, :vanity_url => /[A-Za-z\.0-9\-\_\%\+]*/
          match '/explore/gallery' => 'explore#gallery'
          match '/api/search_v2' => 'api#search_area'
          match '/api/lightframe_data' => 'api#lightframe_data'
          match '/api/shopdetails/edit' => 'api#shop_details_edit', :via => :post
          match '/api/shop/remove_logo' => 'shop_pages#delete_logo_picture', :via => :post
      end
      match 'v2/logout' => '::login#deleteV2'
  end



  #LOGBOOK
  match '/:vanity_url/posts' => 'blog#home', :content => :user, :content_type => :user_published, :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/posts/drafts' => 'blog#home', :content => :user, :content_type => :user_draft, :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/posts/rejected' => 'blog#home', :content => :user, :content_type => :user_rejected, :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/posts/pending' => 'blog#home', :content => :user, :content_type => :user_pending, :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/posts/published' => 'blog#home', :content => :user, :content_type => :user_selected, :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/posts/preview/:id' => 'blog#home', :content => :preview_post, :vanity_url => /[A-Za-z\.0-9\-\_]*/, :id => /[A-Za-z0-9]+/


  match '/:vanity_url/posts/:title' => 'blog#home', :content => :post, :category => /[A-Za-z\.0-9\-\_]*/, :year=> /[0-9]+/, :month=> /[0-9]+/, :vanity_url => /[A-Za-z\.0-9\-\_]*/



  ## DIVE functions CRUD
  match '/:vanity_url/:id/update' => 'diveinfo#update', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :id => /[0-9a-zA-Z]+/
  match '/:vanity_url/:id/delete' => 'diveinfo#delete', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :id => /[0-9a-zA-Z]+/
  match '/:vanity_url/:id/profile' => 'diveinfo#profile', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :id => /[0-9a-zA-Z]+/
  match '/:vanity_url/create' => 'diveinfo#create', :vanity_url => /[A-Za-z\.0-9\-\_]*/

  #when opening a dive default goes to profile
  match '/:vanity_url/:dive.js' => 'diveinfo#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /[0-9]*/, :format => /js/
  match '/:vanity_url/partial/:dive' => 'diveinfo#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /[0-9]*/
  match '/:vanity_url/partial/new' => 'diveinfo#new', :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/partial/bulk' => 'diveinfo#bulk_page', :vanity_url => /[A-Za-z\.0-9\-\_]*/

  ## Logbook functons
  match '/:vanity_url' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :home, :tab => :info
  match '/:vanity_url/community' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :home, :tab => :community
  match '/:vanity_url/wallet' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :home, :tab => :wallet
  match '/:vanity_url/info' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :home, :tab => :info
  match '/:vanity_url/widgets' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :home, :tab => :widgets

  match '/:vanity_url/feed' => 'logbook#activity_feed', :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/new' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :new_dive
  match '/:vanity_url/new/edit' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :new_dive

  match '/:vanity_url/bulk' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :bulk
  match '/:vanity_url/form_review' => 'logbook#get_form_review', :vanity_url => /[A-Za-z\.0-9\-\_]*/
  match '/:vanity_url/trip/:tripid-:tripname' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :tripid => /[0-9]+/, :content => :trip
  match '/:vanity_url/trip/:tripid-'          => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :tripid => /[0-9]+/, :content => :trip
  ## Picture functions
  match '/:vanity_url/pictures/:picture_id' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :picture_id => /[0-9]*/, :content => :picture
  match '/:vanity_url/play_vid/:picture_id' => 'pictures#read_video', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :picture_id => /[0-9]*/, :content => :picture
  match '/:vanity_url/videojump/:picture_id' => 'pictures#video_redirect', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :picture_id => /[0-9]*/

  match '/:vanity_url/widget' => 'logbook#widget', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :content => :profile, :tab => :widget



  match '/:vanity_url/:dive' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /D[0-9a-zA-Z]+/, :content => :dive
  match '/:vanity_url/:dive' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /d[0-9]+/, :content => :dive
  match '/:vanity_url/:dive' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /[0-9]+/, :content => :dive
  match '/:vanity_url/:dive/edit' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /D[0-9a-zA-Z]+/, :content => :dive, :edit => true
  match '/:vanity_url/:dive/edit' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /d[0-9]+/, :content => :dive, :edit => true
  match '/:vanity_url/:dive/edit' => 'logbook#read', :vanity_url => /[A-Za-z\.0-9\-\_]*/, :dive => /[0-9]+/, :content => :dive, :edit => true
  #if RAILS_ENV != 'production'


end
