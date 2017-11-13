
env :MAILTO, 'root@diveboard.com' 

set :environment, ENV["RAILS_ENV"]||"development"


job_type :rake,      "cd :path && RAILS_ENV=:environment :path/script/cronic bundle exec rake :task"
job_type :nice_rake,      "cd :path && RAILS_ENV=:environment :path/script/cronic nice -19 bundle exec rake :task"
job_type :runner, "cd :path && :path/script/cronic bundle exec rails runner -e :environment ':task'"
job_type :command, "cd :path && :path/script/cronic :task"
job_type :nice_command, "cd :path && :path/script/cronic nice -19 :task"

job_type :fortnight_nice_rake,      "expr \\( \\( `date +\\%s` / 604800 \\) + 1 \\) \\% 2 > /dev/null || cd :path && RAILS_ENV=:environment :path/script/cronic nice -19 bundle exec rake :task"

every :sunday, :at => '12pm' do # Use any day of the week or :weekend, :weekday 
  runner "script/export_gbif.rb"
end
every 15.minutes do
  rake "jobs:dbcheck"
end
every 1.day, :at => '2am' do
  rake "purge:pictures"
  rake "sanity:picture_upload"
end

every 1.day, :at => '11am' do
  rake "email_notify:new_message_for_shops"
end

every 1.day, :at => '10am' do
  runner "script/update_gbif-ipt.rb"
end

every :wednesday, :at => '4am' do
  rake "purge:db"
end
every :monday, :at => '3pm' do
  runner "ActivityFeed.clear_old_objects"
end

every :monday, :at => '9am' do
  rake "email_marketing:onboarding"
end

every :sunday, :at => '3pm' do
  nice_command "script/filter_log.rb --input log/production.log.1 --output log/filtered_logs/filtered.log --timed --anytime"
end

every :tuesday, :at => '4am' do
  nice_rake "assets:all"
end
every 1.day, :at => '7am' do
  runner "(Picture.where 'thumb_id is null or small_id is null or medium_id is null or large_id is null or original_image_id is null').map &:upload_thumbs"
end
every "40 * * * *" do # 40 minutes after every hour
  #TODO reactivate at some point: rake "stats:import"
end
every 1.day, :at => '6pm' do
  runner "Review.notify_missing!"
end

# every 1.day, :at => '11am' do
#   runner "Picture.where(:great_pic => true).where('fb_graph_id is null').first.publish_to_fb_page"
# end

## REFRESHING CACHES
every 15.minutes do
  #refresh the homepage cache
  rake "cache:homepage"
  #refresh the feed for non logged in users
  runner "ApplicationController.new.render_to_string :partial => 'feeds/default_activity_feed', :locals => {:cookies => {}, :force_refresh => true}"
end
every :monday do
  runner "ApplicationController.new.render_to_string :partial => 'admin/charts', :locals => {:cookies => {}, :force_refresh => true}"
  runner "ApplicationController.new.render_to_string :partial => 'admin/statistics', :locals => {:cookies => {}, :force_refresh => true}"
end
every :wednesday do
  rake "cache:charts"
end
every :tuesday, :at => '1pm' do
  rake "cache:best_pics"
end
every 1.day, :at => '1pm' do
  rake "cache:scores"
end
every :sunday, :at => '6pm' do
  rake "seo:store_kpi"
end

#Paypal transaction checks
every 1.hour do
  runner "Basket.where(:paypal_attention => true).each do |basket| begin basket.check_status! rescue nil end; end"
end

every 1.day, :at => '5:00 am' do
  rake "-s sitemap:refresh"
end

every 1.day, :at => '3pm' do
  rake "email_notify:send_digests"
end

every 2.day, :at => '6pm' do
  rake "facebook:post_great_pic"
end


## SPHINX INDEXING
every 3.hour do
  command "/usr/bin/indexer --config /home/diveboard/diveboard-web/current/config/production.sphinx.conf --all --rotate"
  #rake "ts:index"  is crashing sphinx - so it has to be done directly with indexer with --rotate option in prod's crontab
end

