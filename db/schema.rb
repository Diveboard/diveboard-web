# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150618115053) do

  create_table "ZZ_users_fb_data", :id => false, :force => true do |t|
    t.integer "user_id",                                  :null => false
    t.string  "field",                    :default => "", :null => false
    t.string  "data",    :limit => 14096
  end

  add_index "ZZ_users_fb_data", ["field"], :name => "field"
  add_index "ZZ_users_fb_data", ["user_id"], :name => "index_ZZ_users_fb_data_on_user_id"

  create_table "activities", :force => true do |t|
    t.string   "tag",         :null => false
    t.integer  "user_id"
    t.integer  "dive_id"
    t.integer  "spot_id"
    t.integer  "location_id"
    t.integer  "region_id"
    t.integer  "country_id"
    t.integer  "shop_id"
    t.integer  "picture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["country_id"], :name => "index_activities_on_country_id"
  add_index "activities", ["dive_id"], :name => "index_activities_on_dive_id"
  add_index "activities", ["location_id"], :name => "index_activities_on_location_id"
  add_index "activities", ["picture_id"], :name => "index_activities_on_picture_id"
  add_index "activities", ["region_id"], :name => "index_activities_on_region_id"
  add_index "activities", ["shop_id"], :name => "index_activities_on_shop_id"
  add_index "activities", ["spot_id"], :name => "index_activities_on_spot_id"
  add_index "activities", ["tag", "user_id", "dive_id", "spot_id", "location_id", "region_id", "country_id", "shop_id", "picture_id"], :name => "index_activities_all"
  add_index "activities", ["user_id"], :name => "index_activities_on_user_id"

  create_table "activity_followings", :force => true do |t|
    t.integer  "follower_id",                    :null => false
    t.boolean  "exclude",     :default => false, :null => false
    t.string   "tag"
    t.integer  "user_id"
    t.integer  "dive_id"
    t.integer  "spot_id"
    t.integer  "location_id"
    t.integer  "region_id"
    t.integer  "country_id"
    t.integer  "shop_id"
    t.integer  "picture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_followings", ["follower_id", "tag", "user_id", "dive_id", "spot_id", "location_id", "region_id", "country_id", "shop_id", "picture_id"], :name => "index_activities_following_all", :unique => true

  create_table "advertisements", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "ended_at"
    t.boolean  "deleted",          :default => false, :null => false
    t.string   "title",                               :null => false
    t.string   "text",                                :null => false
    t.float    "lat"
    t.float    "lng"
    t.integer  "picture_id",                          :null => false
    t.string   "external_url"
    t.boolean  "local_divers",     :default => false, :null => false
    t.boolean  "frequent_divers",  :default => false, :null => false
    t.boolean  "exploring_divers", :default => false, :null => false
    t.integer  "moderate_id"
  end

  add_index "advertisements", ["lat", "lng"], :name => "index_advertisements_on_lat_and_lng"
  add_index "advertisements", ["user_id"], :name => "index_advertisements_on_user_id"

  create_table "albums", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "kind",       :limit => 12, :null => false
  end

  add_index "albums", ["user_id"], :name => "index_albums_on_user_id"

  create_table "api_keys", :force => true do |t|
    t.string   "key"
    t.integer  "user_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_keys", ["key"], :name => "index_api_keys_on_key"
  add_index "api_keys", ["user_id"], :name => "index_api_keys_on_user_id"

  create_table "api_throttle", :primary_key => "lookup", :force => true do |t|
    t.integer "count_noauth"
    t.integer "count_auth",   :default => 0
  end

  create_table "area_categories", :force => true do |t|
    t.integer  "area_id"
    t.string   "category"
    t.integer  "count"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "area_categories", ["area_id"], :name => "index_area_categories_on_area_id"
  add_index "area_categories", ["category", "count"], :name => "index_area_categories_on_category_and_count"

  create_table "areas", :force => true do |t|
    t.float    "minLat"
    t.float    "minLng"
    t.float    "maxLat"
    t.float    "maxLng"
    t.integer  "elevation"
    t.integer  "geonames_core_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.integer  "january"
    t.integer  "february"
    t.integer  "march"
    t.integer  "april"
    t.integer  "may"
    t.integer  "june"
    t.integer  "july"
    t.integer  "august"
    t.integer  "september"
    t.integer  "october"
    t.integer  "november"
    t.integer  "december"
    t.string   "url_name"
    t.boolean  "active",              :default => false
    t.integer  "favorite_picture_id"
  end

  add_index "areas", ["geonames_core_id"], :name => "index_areas_on_geonames_core_id"
  add_index "areas", ["minLat", "maxLat", "minLng", "maxLng", "active"], :name => "index_areas_on_coordinate_and_active"
  add_index "areas", ["url_name"], :name => "index_areas_on_url_name"

  create_table "auth_tokens", :force => true do |t|
    t.string   "token",                   :null => false
    t.integer  "user_id",    :limit => 8, :null => false
    t.datetime "expires",                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key"
  end

  add_index "auth_tokens", ["token"], :name => "index_auth_tokens_on_token"
  add_index "auth_tokens", ["user_id"], :name => "index_auth_tokens_on_user_id"

  create_table "basket_histories", :force => true do |t|
    t.integer  "basket_id",  :null => false
    t.string   "new_status"
    t.text     "detail",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "basket_histories", ["basket_id"], :name => "index_basket_histories_on_basket_id"

  create_table "basket_items", :force => true do |t|
    t.integer  "basket_id"
    t.integer  "good_to_sell_id"
    t.text     "good_to_sell_archive"
    t.integer  "quantity"
    t.float    "price"
    t.float    "tax"
    t.float    "total"
    t.string   "currency"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deposit_option",       :default => false, :null => false
    t.float    "deposit"
  end

  add_index "basket_items", ["basket_id"], :name => "index_basket_items_on_basket_id"
  add_index "basket_items", ["good_to_sell_id"], :name => "index_basket_items_on_good_to_sell_id"

  create_table "baskets", :force => true do |t|
    t.integer  "user_id"
    t.integer  "shop_id"
    t.text     "comment"
    t.text     "note_from_shop"
    t.string   "in_reply_to_type"
    t.integer  "in_reply_to_id"
    t.string   "status",                                  :default => "open"
    t.text     "delivery_address"
    t.float    "paypal_fees"
    t.string   "paypal_fees_currency"
    t.float    "diveboard_fees"
    t.string   "diveboard_fees_currency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "paypal_order_id",         :limit => 25
    t.datetime "paypal_order_date"
    t.string   "paypal_auth_id",          :limit => 25
    t.datetime "paypal_auth_date"
    t.string   "paypal_capture_id",       :limit => 25
    t.datetime "paypal_capture_date"
    t.string   "paypal_refund_id",        :limit => 25
    t.datetime "paypal_refund_date"
    t.string   "paypal_issue",            :limit => 2048
    t.boolean  "paypal_attention",                        :default => false,  :null => false
  end

  add_index "baskets", ["shop_id", "user_id", "paypal_order_date"], :name => "index_baskets_on_shop_id_and_user_id_and_paypal_order_date"
  add_index "baskets", ["user_id", "shop_id", "paypal_order_date"], :name => "index_baskets_on_user_id_and_shop_id_and_paypal_order_date"

  create_table "blog_categories", :force => true do |t|
    t.string   "name"
    t.string   "blob"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blog_categories", ["blob"], :name => "index_blog_categories_on_blob"
  add_index "blog_categories", ["name"], :name => "index_blog_categories_on_name"

  create_table "blog_posts", :force => true do |t|
    t.integer  "blog_category_id",                :default => 1
    t.integer  "user_id"
    t.string   "blob"
    t.boolean  "published",                       :default => false
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "wordpress_article",               :default => false
    t.boolean  "flag_moderate_private_to_public", :default => false
    t.boolean  "comments_question",               :default => false
    t.string   "fb_graph_id"
    t.boolean  "delta",                           :default => true,  :null => false
  end

  add_index "blog_posts", ["blob"], :name => "index_blog_posts_on_blob"
  add_index "blog_posts", ["delta"], :name => "index_blog_posts_on_delta"
  add_index "blog_posts", ["published", "published_at"], :name => "index_blog_posts_on_published_and_published_at"
  add_index "blog_posts", ["user_id", "published_at"], :name => "index_blog_posts_on_user_id_and_published_at"

  create_table "cloud_objects", :force => true do |t|
    t.string   "bucket",     :null => false
    t.string   "path",       :null => false
    t.string   "etag",       :null => false
    t.integer  "size",       :null => false
    t.text     "meta"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_flags", :force => true do |t|
    t.string  "type"
    t.text    "data"
    t.integer "user_id"
    t.integer "object_id"
    t.string  "object_type", :limit => 8
  end

  create_table "countries", :force => true do |t|
    t.string   "cname"
    t.string   "ccode"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "blob"
    t.string   "nesw_bounds"
    t.string   "best_pic_ids"
  end

  add_index "countries", ["blob"], :name => "index_countries_on_blob"
  add_index "countries", ["ccode"], :name => "ccode", :unique => true

  create_table "countries_regions", :id => false, :force => true do |t|
    t.integer "country_id"
    t.integer "region_id"
  end

  add_index "countries_regions", ["country_id", "region_id"], :name => "index_countries_regions_on_country_id_and_region_id"
  add_index "countries_regions", ["region_id", "country_id"], :name => "region_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",                           :default => 0
    t.integer  "attempts",                           :default => 0
    t.text     "handler",      :limit => 2147483647
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
    t.string   "locale"
    t.boolean  "alert_ignore",                       :default => false
  end

  add_index "delayed_jobs", ["failed_at"], :name => "failed_at"

  create_table "disqus_comments", :force => true do |t|
    t.string   "comment_id"
    t.string   "thread_id"
    t.string   "thread_link"
    t.string   "forum_id"
    t.string   "parent_comment_id"
    t.text     "body"
    t.string   "author_name"
    t.string   "author_email"
    t.string   "author_url"
    t.datetime "date"
    t.string   "source_type"
    t.integer  "source_id"
    t.integer  "diveboard_id"
    t.string   "connections"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "disqus_comments", ["comment_id"], :name => "index_disqus_comments_on_comment_id", :unique => true
  add_index "disqus_comments", ["source_type", "source_id"], :name => "index_disqus_comments_on_source_type_and_source_id"

  create_table "dive_gears", :force => true do |t|
    t.integer  "dive_id",                                       :null => false
    t.string   "manufacturer"
    t.string   "model"
    t.boolean  "featured",                   :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category",     :limit => 10,                    :null => false
  end

  add_index "dive_gears", ["dive_id"], :name => "index_dive_gears_on_dive_id"

  create_table "dive_reviews", :force => true do |t|
    t.integer  "dive_id",    :null => false
    t.string   "name",       :null => false
    t.integer  "mark",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dive_reviews", ["dive_id"], :name => "index_dive_reviews_on_dive_id"

  create_table "dive_using_user_gears", :force => true do |t|
    t.integer  "user_gear_id",                    :null => false
    t.integer  "dive_id",                         :null => false
    t.boolean  "featured",     :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dive_using_user_gears", ["dive_id"], :name => "index_dive_using_user_gears_on_dive_id"
  add_index "dive_using_user_gears", ["user_gear_id"], :name => "index_dive_using_user_gears_on_user_gear_id"

  create_table "dives", :force => true do |t|
    t.datetime "time_in",                                                                    :default => '2011-01-01 00:00:00', :null => false
    t.integer  "duration",                                                                   :default => 0,                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                :limit => 8,                                                                           :null => false
    t.string   "graph_id"
    t.integer  "spot_id",                                                                    :default => 1,                     :null => false
    t.decimal  "maxdepth",                                     :precision => 8, :scale => 3, :default => 0.0,                   :null => false
    t.text     "notes"
    t.float    "temp_surface"
    t.float    "temp_bottom"
    t.integer  "favorite_picture"
    t.integer  "privacy",                                                                    :default => 0,                     :null => false
    t.string   "safetystops"
    t.text     "divetype"
    t.boolean  "favorite"
    t.integer  "uploaded_profile_id"
    t.integer  "uploaded_profile_index"
    t.text     "buddies"
    t.string   "visibility",             :limit => 9
    t.string   "water",                  :limit => 5
    t.float    "altitude"
    t.float    "weights"
    t.text     "dan_data",               :limit => 2147483647
    t.string   "current",                :limit => 7
    t.text     "dan_data_sent",          :limit => 2147483647
    t.integer  "number"
    t.datetime "graph_lint"
    t.integer  "shop_id"
    t.string   "guide"
    t.integer  "trip_id"
    t.integer  "album_id"
    t.integer  "score",                                                                      :default => -100,                  :null => false
    t.float    "maxdepth_value"
    t.string   "maxdepth_unit"
    t.float    "altitude_value"
    t.string   "altitude_unit"
    t.string   "temp_bottom_unit"
    t.float    "temp_bottom_value"
    t.string   "temp_surface_unit"
    t.float    "temp_surface_value"
    t.string   "weights_unit"
    t.float    "weights_value"
    t.boolean  "delta",                                                                      :default => true,                  :null => false
    t.integer  "surface_interval"
  end

  add_index "dives", ["album_id"], :name => "index_dives_on_album_id"
  add_index "dives", ["delta"], :name => "index_dives_on_delta"
  add_index "dives", ["score"], :name => "index_dives_on_score"
  add_index "dives", ["shop_id"], :name => "index_dives_on_shop_id"
  add_index "dives", ["spot_id", "time_in"], :name => "index_dives_on_spot_id_and_time_in"
  add_index "dives", ["time_in"], :name => "index_dives_on_time_in"
  add_index "dives", ["trip_id"], :name => "index_dives_on_trip_id"
  add_index "dives", ["uploaded_profile_id"], :name => "uploaded_profile_id"
  add_index "dives", ["user_id", "time_in"], :name => "index_dives_on_user_id_and_time_in"

  create_table "dives_buddies", :force => true do |t|
    t.integer "dive_id",    :null => false
    t.string  "buddy_type", :null => false
    t.integer "buddy_id",   :null => false
  end

  add_index "dives_buddies", ["buddy_id", "buddy_type"], :name => "index_dives_buddies_on_buddy_id_and_buddy_type"
  add_index "dives_buddies", ["dive_id"], :name => "index_dives_buddies_on_dive_id"

  create_table "dives_eolcnames", :id => false, :force => true do |t|
    t.integer "dive_id"
    t.integer "sname_id"
    t.integer "cname_id"
  end

  add_index "dives_eolcnames", ["cname_id"], :name => "index_dives_eolcnames_on_cname_id"
  add_index "dives_eolcnames", ["dive_id"], :name => "index_dives_eolcnames_on_dive_id"
  add_index "dives_eolcnames", ["sname_id"], :name => "index_dives_eolcnames_on_sname_id"

  create_table "dives_fish", :id => false, :force => true do |t|
    t.integer "dive_id"
    t.integer "fish_id"
  end

  add_index "dives_fish", ["dive_id"], :name => "index_dives_fish_on_dive_id"
  add_index "dives_fish", ["fish_id"], :name => "index_dives_fish_on_fish_id"

  create_table "email_subscriptions", :force => true do |t|
    t.string   "email"
    t.string   "scope"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "subscribed"
    t.string   "recipient_type"
    t.integer  "recipient_id"
  end

  add_index "email_subscriptions", ["email"], :name => "index_unsubscribes_on_email"
  add_index "email_subscriptions", ["scope"], :name => "index_unsubscribes_on_scope"

  create_table "emails_marketing", :force => true do |t|
    t.integer  "target_id"
    t.string   "target_type"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.string   "email"
    t.string   "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emails_marketing", ["content"], :name => "index_emails_marketing_on_content"
  add_index "emails_marketing", ["email"], :name => "index_emails_marketing_on_email"

  create_table "eolcnames", :force => true do |t|
    t.integer  "eolsname_id"
    t.string   "cname"
    t.string   "language"
    t.boolean  "eol_preferred"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "eolcnames", ["eolsname_id"], :name => "index_eolcnames_on_eolsname_id"

  create_table "eolsnames", :force => true do |t|
    t.string   "sname"
    t.text     "taxon"
    t.text     "data",               :limit => 2147483647
    t.integer  "picture"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gbif_id"
    t.integer  "worms_id"
    t.integer  "fishbase_id"
    t.integer  "worms_parent_id"
    t.integer  "fishbase_parent_id"
    t.string   "worms_taxonrank",    :limit => 7
    t.string   "fishbase_taxonrank", :limit => 7
    t.text     "worms_hierarchy"
    t.text     "fishbase_hierarchy"
    t.string   "category"
    t.string   "taxonrank"
    t.string   "parent_id"
    t.boolean  "has_occurences",                           :default => false
    t.text     "eol_description",    :limit => 2147483647
    t.string   "thumbnail_href"
    t.string   "category_inspire"
  end

  add_index "eolsnames", ["category"], :name => "index_eolsnames_2_on_category"
  add_index "eolsnames", ["fishbase_id"], :name => "index_eolsnames_2_on_fishbase_id"
  add_index "eolsnames", ["fishbase_parent_id"], :name => "index_eolsnames_2_on_fishbase_parent_id"
  add_index "eolsnames", ["fishbase_taxonrank"], :name => "index_eolsnames_2_on_fishbase_taxonrank"
  add_index "eolsnames", ["gbif_id"], :name => "index_eolsnames_2_on_gbif_id"
  add_index "eolsnames", ["parent_id"], :name => "index_eolsnames_on_parent_id"
  add_index "eolsnames", ["taxonrank"], :name => "index_eolsnames_on_taxonrank"
  add_index "eolsnames", ["worms_id"], :name => "index_eolsnames_2_on_worms_id"
  add_index "eolsnames", ["worms_parent_id"], :name => "index_eolsnames_2_on_worms_parent_id"
  add_index "eolsnames", ["worms_taxonrank"], :name => "index_eolsnames_2_on_worms_taxonrank"

  create_table "external_users", :force => true do |t|
    t.integer  "fb_id",      :limit => 8
    t.text     "nickname"
    t.string   "email"
    t.text     "picturl"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "external_users", ["email"], :name => "index_external_users_on_email"
  add_index "external_users", ["fb_id"], :name => "index_external_users_on_fb_id"

  create_table "fb_comments", :force => true do |t|
    t.string   "source_type"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_data",    :limit => 2147483647
  end

  add_index "fb_comments", ["source_id"], :name => "index_fb_comments_on_source_id"
  add_index "fb_comments", ["source_type"], :name => "index_fb_comments_on_source_type"

  create_table "fb_likes", :force => true do |t|
    t.string   "source_type",       :default => "", :null => false
    t.integer  "source_id",                         :null => false
    t.string   "url",               :default => "", :null => false
    t.integer  "click_count"
    t.integer  "comment_count"
    t.integer  "comments_fbid"
    t.integer  "commentsbox_count"
    t.integer  "like_count"
    t.integer  "share_count"
    t.integer  "total_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fb_likes", ["source_type", "source_id"], :name => "index_fb_likes_on_source_type_and_source_id"
  add_index "fb_likes", ["source_type", "source_id"], :name => "source_type"
  add_index "fb_likes", ["url"], :name => "index_fb_likes_on_url", :unique => true

  create_table "fish_frequencies", :force => true do |t|
    t.integer  "gbif_id",    :null => false
    t.integer  "lat",        :null => false
    t.integer  "lng",        :null => false
    t.integer  "count",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fish_frequencies", ["gbif_id"], :name => "index_fish_frequencies_on_gbif_id"
  add_index "fish_frequencies", ["lat", "lng", "count"], :name => "index_fish_frequencies_on_lat_and_lng_and_count"

  create_table "gbif_ipts", :force => true do |t|
    t.integer "dive_id"
    t.integer "eol_id"
    t.string  "g_modified"
    t.string  "g_institutionCode"
    t.string  "g_references"
    t.string  "g_catalognumber"
    t.string  "g_scientificnName"
    t.string  "g_basisOfRecord"
    t.string  "g_nameAccordingTo"
    t.string  "g_dateIdentified"
    t.string  "g_bibliographicCitation"
    t.string  "g_kingdom"
    t.string  "g_phylum"
    t.string  "g_class"
    t.string  "g_order"
    t.string  "g_family"
    t.string  "g_genus"
    t.string  "g_specificEpithet"
    t.string  "g_infraspecificEpitet"
    t.string  "g_scientificNameAuthorship"
    t.string  "g_identifiedBy"
    t.string  "g_recordedBy"
    t.string  "g_eventDate"
    t.string  "g_eventTime"
    t.string  "g_higherGeographyID"
    t.string  "g_country"
    t.string  "g_locality"
    t.string  "g_decimalLongitude"
    t.string  "g_decimallatitude"
    t.string  "g_CoordinatePrecision"
    t.string  "g_MinimumDepth"
    t.string  "g_MaximumDepth"
    t.string  "g_Temperature"
    t.string  "g_Continent"
    t.string  "g_waterBody"
    t.string  "g_eventRemarks"
    t.string  "g_fieldnotes"
    t.string  "g_locationRemarks"
    t.string  "g_type"
    t.string  "g_language"
    t.string  "g_rights"
    t.string  "g_rightsholder"
    t.string  "g_datasetID"
    t.string  "g_datasetName"
    t.string  "g_ownerintitutionCode"
    t.string  "g_countryCode"
    t.string  "g_geodeticDatim"
    t.string  "g_georeferenceSources"
    t.string  "g_minimumElevationInMeters"
    t.string  "g_maximumElevationInMeters"
    t.string  "g_taxonID"
    t.string  "g_nameAccordingToID"
    t.string  "g_taxonRankvernacularName"
    t.string  "g_occurrenceID"
    t.string  "g_associatedMedia"
    t.string  "g_eventID"
    t.string  "g_habitat"
  end

  add_index "gbif_ipts", ["dive_id"], :name => "index_gbif_ipts_on_dive_id"
  add_index "gbif_ipts", ["eol_id"], :name => "index_gbif_ipts_on_eol_id"

  create_table "geonames_alternate_names", :force => true do |t|
    t.integer "geoname_id"
    t.string  "language"
    t.string  "name"
    t.boolean "preferred"
    t.boolean "short_name"
    t.boolean "colloquial"
    t.boolean "historic"
  end

  add_index "geonames_alternate_names", ["geoname_id", "language", "preferred"], :name => "index_geoname_id"
  add_index "geonames_alternate_names", ["name"], :name => "index_geonames_alternate_names_stage_utf8_on_name"

  create_table "geonames_cores", :force => true do |t|
    t.string  "name",           :limit => 200
    t.string  "asciiname",      :limit => 200
    t.string  "alternatenames", :limit => 5000
    t.float   "latitude"
    t.float   "longitude"
    t.string  "feature_class",  :limit => 1
    t.string  "feature_code",   :limit => 10
    t.string  "country_code",   :limit => 5
    t.string  "cc2",            :limit => 60
    t.string  "admin1_code",    :limit => 20
    t.string  "admin2_code",    :limit => 80
    t.string  "admin3_code",    :limit => 20
    t.string  "admin4_code",    :limit => 20
    t.integer "population",     :limit => 8
    t.integer "elevation"
    t.integer "gtopo30"
    t.string  "timezone_id"
    t.date    "updated_at"
    t.integer "parent_id"
    t.string  "hierarchy_adm"
  end

  add_index "geonames_cores", ["asciiname", "country_code"], :name => "index_geonames_cores_on_asciiname_and_country_code"
  add_index "geonames_cores", ["country_code"], :name => "index_geonames_cores_on_country_code"
  add_index "geonames_cores", ["feature_class"], :name => "index_geonames_cores_on_feature_class"
  add_index "geonames_cores", ["feature_code"], :name => "index_geonames_cores_on_feature_code"
  add_index "geonames_cores", ["latitude", "longitude"], :name => "index_geonames_cores_on_latitude_and_longitude"
  add_index "geonames_cores", ["name", "country_code"], :name => "index_geonames_cores_on_name_and_country_code"
  add_index "geonames_cores", ["parent_id"], :name => "index_geonames_cores_on_parent_id"

  create_table "geonames_countries", :force => true do |t|
    t.string  "ISO",             :limit => 2
    t.string  "ISO3",            :limit => 3
    t.string  "ISONumeric",      :limit => 3
    t.string  "name"
    t.string  "capital"
    t.integer "area"
    t.integer "population"
    t.string  "continent",       :limit => 2
    t.string  "tld",             :limit => 4
    t.string  "currency_code",   :limit => 3
    t.string  "currency_name",   :limit => 30
    t.string  "currency_symbol", :limit => 6
    t.string  "phone",           :limit => 10
    t.string  "postcode",        :limit => 10
    t.string  "postcode_regexp"
    t.string  "languages"
    t.integer "geonames_id"
    t.string  "neighbours"
    t.string  "depends_from"
    t.string  "feature_code",    :limit => 10
  end

  add_index "geonames_countries", ["ISO"], :name => "index_geonames_countries_on_ISO"
  add_index "geonames_countries", ["ISO3"], :name => "index_geonames_countries_on_ISO3"
  add_index "geonames_countries", ["continent"], :name => "index_geonames_countries_on_continent"
  add_index "geonames_countries", ["geonames_id"], :name => "index_geonames_countries_on_geonames_id"

  create_table "geonames_featurecodes", :force => true do |t|
    t.string "feature_code", :limit => 10
    t.string "name"
    t.string "description"
  end

  add_index "geonames_featurecodes", ["feature_code"], :name => "index_geonames_featurecodes_on_feature_code"

  create_table "goods_to_sell", :force => true do |t|
    t.integer  "shop_id",                                        :null => false
    t.string   "realm",                                          :null => false
    t.string   "cat1"
    t.string   "cat2"
    t.string   "cat3"
    t.text     "title",                                          :null => false
    t.text     "description"
    t.integer  "picture_id"
    t.string   "stock_type"
    t.integer  "stock_id"
    t.string   "price_type"
    t.float    "price"
    t.float    "tax"
    t.float    "total"
    t.string   "currency",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_num",                :default => -1,       :null => false
    t.string   "status",      :limit => 7, :default => "public", :null => false
    t.float    "deposit"
  end

  add_index "goods_to_sell", ["shop_id", "realm", "status", "order_num"], :name => "goods_to_sell_on_shop_id"

  create_table "i18n_languages", :force => true do |t|
    t.string "code3"
    t.string "code2"
    t.string "lang"
    t.string "name"
  end

  add_index "i18n_languages", ["code2", "lang"], :name => "index_i18n_languages_on_code2_and_lang"
  add_index "i18n_languages", ["code3", "lang"], :name => "index_i18n_languages_on_code3_and_lang"

  create_table "internal_messages", :force => true do |t|
    t.integer  "from_id"
    t.integer  "from_group_id"
    t.integer  "to_id"
    t.string   "topic"
    t.text     "message"
    t.string   "in_reply_to_type"
    t.integer  "in_reply_to_id"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",           :default => "new", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "nesw_bounds"
    t.integer  "verified_user_id"
    t.datetime "verified_date"
    t.integer  "redirect_id"
    t.string   "best_pic_ids"
    t.boolean  "delta",            :default => true, :null => false
  end

  add_index "locations", ["country_id"], :name => "index_locations_on_country_id"
  add_index "locations", ["delta"], :name => "index_locations_on_delta"
  add_index "locations", ["name"], :name => "index_locations_on_name"

  create_table "locations_regions", :id => false, :force => true do |t|
    t.integer "location_id"
    t.integer "region_id"
  end

  add_index "locations_regions", ["location_id", "region_id"], :name => "index_locations_regions_on_location_id_and_region_id"

  create_table "memberships", :force => true do |t|
    t.integer  "user_id",                 :null => false
    t.integer  "group_id",                :null => false
    t.string   "role",       :limit => 6, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["group_id", "role"], :name => "index_memberships_on_group_id_and_role"
  add_index "memberships", ["user_id", "role"], :name => "index_memberships_on_user_id_and_role"

  create_table "mod_histories", :force => true do |t|
    t.integer  "obj_id"
    t.string   "table"
    t.integer  "operation"
    t.text     "before"
    t.text     "after"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletter_users", :force => true do |t|
    t.integer  "newsletter_id"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletters", :force => true do |t|
    t.text     "html_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "distributed_at"
    t.text     "reports"
    t.integer  "sending_pid"
    t.string   "title"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.string   "kind",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "dismissed_at"
    t.string   "about_type",   :null => false
    t.integer  "about_id",     :null => false
    t.text     "param"
  end

  add_index "notifications", ["user_id", "created_at"], :name => "index_notifications_on_user_id_and_created_at"

  create_table "payments", :force => true do |t|
    t.integer  "user_id",                                                  :null => false
    t.string   "category",                                                 :null => false
    t.integer  "subscription_plan_id"
    t.string   "status",               :limit => 9, :default => "pending", :null => false
    t.date     "confirmation_date"
    t.date     "cancellation_date"
    t.date     "refund_date"
    t.date     "validity_date"
    t.float    "amount",                                                   :null => false
    t.boolean  "recurring",                         :default => false,     :null => false
    t.text     "ref_paypal"
    t.text     "comment"
    t.integer  "storage_duration",     :limit => 8
    t.integer  "storage_limit",        :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "rec_profile_paypal"
    t.integer  "shop_id"
    t.integer  "donation"
  end

  add_index "payments", ["user_id", "status"], :name => "index_payments_on_user_id_and_status"

  create_table "picture_album_pictures", :id => false, :force => true do |t|
    t.integer "picture_album_id", :null => false
    t.integer "picture_id",       :null => false
    t.integer "ordnum",           :null => false
  end

  add_index "picture_album_pictures", ["picture_album_id", "ordnum", "picture_id"], :name => "picture_album_pictures_on_album"
  add_index "picture_album_pictures", ["picture_id"], :name => "index_picture_album_pictures_on_picture_id"

  create_table "pictures", :force => true do |t|
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "href"
    t.string   "cache"
    t.integer  "user_id"
    t.text     "notes"
    t.integer  "small_id"
    t.integer  "medium_id"
    t.integer  "size",                                        :default => 0,       :null => false
    t.string   "media",                 :limit => 5,          :default => "image", :null => false
    t.integer  "webm"
    t.integer  "mp4"
    t.text     "exif",                  :limit => 2147483647
    t.integer  "thumb_id"
    t.integer  "large_id"
    t.integer  "large_fb_id"
    t.string   "original_image_path"
    t.string   "original_video_path"
    t.integer  "original_image_id"
    t.integer  "original_video_id"
    t.boolean  "great_pic"
    t.integer  "width"
    t.integer  "height"
    t.string   "original_content_type"
    t.string   "fb_graph_id"
  end

  add_index "pictures", ["large_id"], :name => "index_pictures_on_large_id"
  add_index "pictures", ["medium_id"], :name => "index_pictures_on_medium_id"
  add_index "pictures", ["mp4"], :name => "index_pictures_on_mp4"
  add_index "pictures", ["original_image_id"], :name => "index_pictures_on_original_image_id"
  add_index "pictures", ["original_video_id"], :name => "index_pictures_on_original_video_id"
  add_index "pictures", ["small_id"], :name => "index_pictures_on_small_id"
  add_index "pictures", ["thumb_id"], :name => "index_pictures_on_thumb_id"
  add_index "pictures", ["updated_at"], :name => "index_pictures_on_dive_id_and_updated_at"
  add_index "pictures", ["updated_at"], :name => "index_pictures_on_updated_at"
  add_index "pictures", ["user_id"], :name => "index_pictures_on_user_id"
  add_index "pictures", ["webm"], :name => "index_pictures_on_webm"

  create_table "pictures_eolcnames", :id => false, :force => true do |t|
    t.integer "picture_id"
    t.integer "sname_id"
    t.integer "cname_id"
  end

  add_index "pictures_eolcnames", ["cname_id"], :name => "index_pictures_eolcnames_on_cname_id"
  add_index "pictures_eolcnames", ["picture_id"], :name => "index_pictures_eolcnames_on_picture_id"
  add_index "pictures_eolcnames", ["sname_id"], :name => "index_pictures_eolcnames_on_sname_id"

  create_table "profile_data", :force => true do |t|
    t.integer "dive_id",                                      :null => false
    t.integer "seconds",                                      :null => false
    t.float   "depth"
    t.float   "current_water_temperature"
    t.float   "main_cylinder_pressure"
    t.float   "heart_beats"
    t.boolean "deco_violation",            :default => false, :null => false
    t.boolean "deco_start",                :default => false, :null => false
    t.boolean "ascent_violation",          :default => false, :null => false
    t.boolean "bookmark",                  :default => false, :null => false
    t.boolean "surface_event",             :default => false, :null => false
  end

  add_index "profile_data", ["dive_id", "seconds"], :name => "index_profile_data_on_dive_id_and_seconds"

  create_table "regions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "nesw_bounds"
    t.integer  "verified_user_id"
    t.datetime "verified_date"
    t.integer  "redirect_id"
    t.string   "best_pic_ids"
    t.boolean  "delta",            :default => true, :null => false
    t.integer  "geonames_core_id"
  end

  add_index "regions", ["delta"], :name => "index_regions_on_delta"
  add_index "regions", ["name"], :name => "index_regions_on_name", :unique => true

  create_table "review_votes", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "review_id",  :null => false
    t.boolean  "vote",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "review_votes", ["review_id", "vote"], :name => "index_review_votes_on_review_id_and_vote"
  add_index "review_votes", ["user_id", "review_id"], :name => "index_review_votes_on_user_id_and_review_id"

  create_table "reviews", :force => true do |t|
    t.integer  "user_id",                                        :null => false
    t.integer  "shop_id",                                        :null => false
    t.boolean  "anonymous",                   :default => false, :null => false
    t.boolean  "recommend",                                      :null => false
    t.integer  "mark_orga"
    t.integer  "mark_friend"
    t.integer  "mark_secu"
    t.integer  "mark_boat"
    t.integer  "mark_rent"
    t.text     "title"
    t.text     "comment"
    t.string   "service",       :limit => 10,                    :null => false
    t.boolean  "spam",                        :default => false, :null => false
    t.boolean  "reported_spam",               :default => false, :null => false
    t.boolean  "flag_moderate",               :default => true,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "reply"
  end

  add_index "reviews", ["shop_id", "created_at"], :name => "index_reviews_on_shop_id_and_created_at"
  add_index "reviews", ["user_id", "shop_id"], :name => "index_reviews_on_user_id_and_shop_id", :unique => true

  create_table "seo_logs", :id => false, :force => true do |t|
    t.string   "lookup"
    t.datetime "date"
    t.integer  "idx"
    t.string   "url"
    t.text     "other"
  end

  add_index "seo_logs", ["date"], :name => "index_seo_logs_on_date"
  add_index "seo_logs", ["lookup"], :name => "index_seo_logs_on_lookup"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shop_customer_detail", :id => false, :force => true do |t|
    t.integer  "shop_id"
    t.integer  "user_id",         :limit => 8
    t.string   "stuff_type",      :limit => 15, :default => "", :null => false
    t.datetime "registered_at"
    t.integer  "dive_id"
    t.integer  "review_id"
    t.integer  "basket_id"
    t.integer  "message_id_from"
    t.integer  "message_id_to"
  end

  create_table "shop_customer_history", :id => false, :force => true do |t|
    t.integer  "shop_id"
    t.integer  "user_id",       :limit => 8
    t.datetime "registered_at"
    t.string   "stuff_type",    :limit => 15, :default => "", :null => false
    t.integer  "stuff_id",      :limit => 8
  end

  create_table "shop_customers", :id => false, :force => true do |t|
    t.integer "id",                 :limit => 8
    t.integer "shop_id"
    t.integer "user_id",            :limit => 8
    t.integer "dive_count",         :limit => 8, :default => 0, :null => false
    t.integer "review_id"
    t.integer "basket_count",       :limit => 8, :default => 0, :null => false
    t.integer "message_to_count",   :limit => 8, :default => 0, :null => false
    t.integer "message_from_count", :limit => 8, :default => 0, :null => false
  end

  create_table "shop_densities", :force => true do |t|
    t.float    "minLat"
    t.float    "minLng"
    t.float    "maxLat"
    t.float    "maxLng"
    t.integer  "shop_density"
    t.integer  "dive_density"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "shop_details", :force => true do |t|
    t.string   "kind"
    t.string   "value",      :limit => 4096
    t.integer  "shop_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "shop_details", ["shop_id", "kind"], :name => "index_shop_details_on_shop_id_and_kind"

  create_table "shop_q_and_as", :force => true do |t|
    t.integer  "shop_id"
    t.string   "question"
    t.string   "answer"
    t.string   "language",   :limit => 3
    t.boolean  "official",                :default => false
    t.integer  "position"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  create_table "shop_widgets", :force => true do |t|
    t.integer  "shop_id"
    t.string   "widget_type",                :null => false
    t.integer  "widget_id",                  :null => false
    t.string   "realm",                      :null => false
    t.string   "set",                        :null => false
    t.integer  "column",      :default => 0, :null => false
    t.integer  "position",    :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shop_widgets", ["shop_id", "set", "realm", "position"], :name => "index_shop_widgets_on_shop_id_and_set_and_realm_and_position"

  create_table "shops", :force => true do |t|
    t.string   "source"
    t.string   "source_id"
    t.string   "kind"
    t.float    "lat"
    t.float    "lng"
    t.string   "name"
    t.text     "address"
    t.string   "email"
    t.string   "web"
    t.string   "phone"
    t.text     "desc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "moderate",                        :default => false, :null => false
    t.string   "shop_vanity"
    t.string   "category"
    t.text     "about_html"
    t.string   "city"
    t.string   "country_code"
    t.string   "facebook"
    t.string   "twitter"
    t.string   "google_plus"
    t.text     "openings"
    t.text     "nearby"
    t.integer  "private_user_id"
    t.boolean  "flag_moderate_private_to_public"
    t.text     "google_geocode"
    t.boolean  "realm_dive"
    t.boolean  "realm_home"
    t.boolean  "realm_gear"
    t.boolean  "realm_travel"
    t.string   "paypal_id"
    t.string   "paypal_token"
    t.string   "paypal_secret"
    t.integer  "score",                           :default => -1,    :null => false
    t.boolean  "delta",                           :default => true,  :null => false
  end

  add_index "shops", ["delta"], :name => "index_shops_on_delta"

  create_table "shops_shared", :id => false, :force => true do |t|
    t.integer "id",           :default => 0,     :null => false
    t.string  "kind"
    t.float   "lat"
    t.float   "lng"
    t.string  "name"
    t.boolean "moderate",     :default => false, :null => false
    t.string  "category"
    t.string  "city"
    t.string  "country_code"
  end

  create_table "signatures", :force => true do |t|
    t.integer  "dive_id"
    t.string   "signby_type"
    t.integer  "signby_id"
    t.text     "signed_data"
    t.datetime "request_date"
    t.datetime "signed_date"
    t.boolean  "rejected",     :default => false
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "signatures", ["dive_id"], :name => "index_signatures_on_dive_id"
  add_index "signatures", ["signby_type", "signby_id"], :name => "signby_type"

  create_table "spot_compare", :id => false, :force => true do |t|
    t.integer "a_id",             :default => 0, :null => false
    t.integer "b_id",             :default => 0, :null => false
    t.integer "dl_dst",           :default => 0, :null => false
    t.float   "1_dst"
    t.integer "untrusted_coord",  :default => 0, :null => false
    t.integer "included"
    t.integer "country_included"
    t.integer "same_country"
    t.integer "same_region"
    t.integer "same_location"
    t.string  "match_class"
    t.integer "cluster_id"
  end

  add_index "spot_compare", ["a_id", "match_class", "b_id"], :name => "spot_compare_idx1"
  add_index "spot_compare", ["b_id", "match_class", "a_id"], :name => "spot_compare_idx2"
  add_index "spot_compare", ["cluster_id", "match_class"], :name => "spot_compare_idx3"

  create_table "spot_moderations", :force => true do |t|
    t.integer  "a_id"
    t.integer  "b_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spot_moderations", ["a_id", "b_id"], :name => "index_spot_moderations_on_a_id_and_b_id"
  add_index "spot_moderations", ["b_id", "a_id"], :name => "index_spot_moderations_on_b_id_and_a_id"

  create_table "spots", :force => true do |t|
    t.string   "name",                                               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "lat",                             :default => 0.0,   :null => false
    t.float    "long",                            :default => 0.0,   :null => false
    t.integer  "zoom",                            :default => 7,     :null => false
    t.integer  "moderate_id"
    t.boolean  "precise",                         :default => false, :null => false
    t.text     "description"
    t.string   "map"
    t.integer  "location_id",                     :default => 1,     :null => false
    t.integer  "region_id"
    t.integer  "country_id",                      :default => 1,     :null => false
    t.integer  "private_user_id"
    t.boolean  "flag_moderate_private_to_public"
    t.integer  "verified_user_id"
    t.datetime "verified_date"
    t.integer  "redirect_id"
    t.boolean  "from_bulk",                       :default => false
    t.boolean  "within_country_bounds"
    t.string   "best_pic_ids"
    t.integer  "score"
    t.boolean  "delta",                           :default => true,  :null => false
  end

  add_index "spots", ["country_id"], :name => "index_spots_on_country_id"
  add_index "spots", ["delta"], :name => "index_spots_on_delta"
  add_index "spots", ["lat", "long"], :name => "index_spots_on_lat_and_long"
  add_index "spots", ["location_id"], :name => "index_spots_on_location_id"
  add_index "spots", ["region_id"], :name => "index_spots_on_region_id"

  create_table "stats_sums", :id => false, :force => true do |t|
    t.string   "aggreg"
    t.datetime "time"
    t.string   "col1"
    t.string   "col2"
    t.integer  "nb"
  end

  add_index "stats_sums", ["aggreg", "time", "col1", "col2"], :name => "index_stats_sums_on_aggreg_and_time_and_col1_and_col2"

  create_table "subscription_plans", :force => true do |t|
    t.string   "category",                           :null => false
    t.string   "name",                               :null => false
    t.string   "title",                              :null => false
    t.string   "option_name",     :default => "1"
    t.string   "option_title",    :default => "1"
    t.integer  "period",          :default => 1,     :null => false
    t.boolean  "available",       :default => true,  :null => false
    t.boolean  "preferred",       :default => false, :null => false
    t.float    "price"
    t.text     "commercial_note"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.string   "url"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tanks", :force => true do |t|
    t.float    "p_start"
    t.float    "p_end"
    t.integer  "time_start"
    t.integer  "o2"
    t.integer  "n2"
    t.integer  "he"
    t.float    "volume"
    t.integer  "dive_id"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "material",      :limit => 9
    t.integer  "multitank",                  :default => 1, :null => false
    t.string   "p_start_unit"
    t.float    "p_start_value"
    t.string   "p_end_unit"
    t.float    "p_end_value"
    t.string   "volume_unit"
    t.float    "volume_value"
    t.string   "gas_type",      :limit => 6
  end

  add_index "tanks", ["dive_id", "order"], :name => "index_tanks_on_dive_id_and_order"

  create_table "treasures", :force => true do |t|
    t.integer  "user_id"
    t.string   "object_type"
    t.integer  "object_id"
    t.string   "campaign_name"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "trips", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "album_id"
  end

  add_index "trips", ["album_id"], :name => "index_trips_on_album_id"
  add_index "trips", ["user_id"], :name => "index_trips_on_user_id"

  create_table "uploaded_profiles", :force => true do |t|
    t.text     "source",                              :null => false
    t.binary   "data",          :limit => 2147483647, :null => false
    t.text     "log"
    t.text     "source_detail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "agent"
    t.integer  "user_id"
  end

  add_index "uploaded_profiles", ["user_id", "created_at"], :name => "index_uploaded_profiles_on_user_id_and_created_at"

  create_table "user_extra_activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "geoname_id"
    t.float    "lat"
    t.float    "lng"
    t.integer  "year"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_gears", :force => true do |t|
    t.integer  "user_id",                                          :null => false
    t.string   "manufacturer"
    t.string   "model"
    t.date     "acquisition"
    t.date     "last_revision"
    t.string   "reference"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category",      :limit => 10,                      :null => false
    t.string   "auto_feature",  :limit => 8,  :default => "never", :null => false
    t.integer  "pref_order"
  end

  add_index "user_gears", ["user_id"], :name => "index_user_gears_on_user_id"

  create_table "users", :force => true do |t|
    t.integer  "fb_id",              :limit => 8
    t.string   "last_name"
    t.string   "first_name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vanity_url"
    t.string   "nickname"
    t.string   "location"
    t.text     "settings"
    t.boolean  "pict"
    t.integer  "admin_rights",                             :default => 0,           :null => false
    t.text     "fbtoken"
    t.text     "password"
    t.string   "contact_email"
    t.text     "fb_permissions"
    t.text     "about"
    t.integer  "total_ext_dives",                          :default => 0,           :null => false
    t.string   "plugin_debug",       :limit => 5
    t.text     "dan_data",           :limit => 2147483647
    t.string   "quota_type",         :limit => 9,          :default => "per_month", :null => false
    t.integer  "quota_limit",        :limit => 8,          :default => 524288000,   :null => false
    t.date     "quota_expire"
    t.integer  "shop_proxy_id"
    t.string   "city"
    t.float    "lat"
    t.float    "lng"
    t.text     "skip_import_dives",  :limit => 16777215
    t.string   "currency"
    t.boolean  "delta",                                    :default => true,        :null => false
    t.string   "source"
    t.string   "preferred_locale",                         :default => "en"
    t.string   "movescount_email"
    t.string   "movescount_userkey"
  end

  add_index "users", ["contact_email"], :name => "contact_email"
  add_index "users", ["delta"], :name => "index_users_on_delta"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["fb_id"], :name => "index_users_on_fb_id"
  add_index "users", ["lat", "lng"], :name => "index_users_on_lat_and_lng"
  add_index "users", ["shop_proxy_id"], :name => "index_users_on_shop_proxy_id"
  add_index "users", ["vanity_url"], :name => "index_users_on_vanity_url"

  create_table "users_buddies", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "buddy_type", :null => false
    t.integer  "buddy_id",   :null => false
    t.datetime "invited_at"
  end

  add_index "users_buddies", ["buddy_id", "buddy_type"], :name => "index_users_buddies_on_buddy_id_and_buddy_type"
  add_index "users_buddies", ["user_id"], :name => "index_users_buddies_on_user_id"

  create_table "widget_list_dives", :force => true do |t|
    t.integer  "owner_id"
    t.string   "from_type",                  :null => false
    t.integer  "from_id",                    :null => false
    t.integer  "limit",      :default => 10, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "widget_picture_banners", :force => true do |t|
    t.integer  "album_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "widget_texts", :force => true do |t|
    t.text     "content"
    t.boolean  "read_only",  :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wikis", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id"
    t.string   "source_type",      :limit => 8
    t.integer  "user_id"
    t.integer  "verified_user_id"
    t.text     "data",             :limit => 2147483647
    t.integer  "album_id"
    t.string   "title"
  end

  add_index "wikis", ["album_id"], :name => "index_wikis_on_album_id"
  add_index "wikis", ["source_id"], :name => "index_wikis_on_object_id"
  add_index "wikis", ["source_type"], :name => "index_wikis_on_object_type"
  add_index "wikis", ["user_id"], :name => "index_wikis_on_user_id"

end
