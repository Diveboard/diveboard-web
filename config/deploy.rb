#require 'bundler/capistrano'
set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'


default_run_options[:pty] = true 
set :keep_releases, 5
set :application, "diveboard"
set :repository,  "git@github.com:Diveboard/diveboard-web.git"
set :scm, :git
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true }

set :use_sudo, false
set :normalize_asset_timestamps, true

set :default_environment, {
    'PATH' => '/var/lib/gems/1.9.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
}



#role :web, "www.diveboard.com"                          # Your HTTP server, Apache/etc
#role :app, "www.diveboard.com"                          # This may be the same as your `Web` server
#role :db,  "www.diveboard.com", :primary => true        # This is where Rails migrations will run


set(:db, 'none') unless exists?(:db)
if !db.nil?
   set :db, db
end

# ==============================
# Common Deploy tasks
# ==============================

before "deploy:bundle_install", "deploy:install_bundler"
after "deploy:update_code", "deploy:bundle_install"
after "deploy:restart", "deploy:migrate"



# Set Symlinks
after "deploy:finalize_update", "uploads:symlink"

#jammit & assets management
after "deploy:migrate", "assets:jammit"

#workers
before "deploy:update_code", "deploy:jobs_stop"

after "deploy:search_rebuild", "deploy:jobs_start"
after "deploy:jobs_start", "deploy:git_gc"


#Rebuild and relaunch sphinx
before "deploy:search_rebuild", "deploy:search_stop"

after "deploy:migrate", "deploy:search_rebuild"

on :start, "uploads:register_dirs"



# ==============================
# links static or existing resources to the new code checkout
# ==============================

namespace :uploads do

  desc <<-EOD
    Creates the upload folders unless they exist
    and sets the proper upload permissions.
  EOD
  task :setup, :except => { :no_release => true } do
    dirs = uploads_dirs.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
  end

  desc <<-EOD
    [internal] Creates the symlink to uploads shared folder
    for the most recently deployed version.
  EOD
  task :symlink, :except => { :no_release => true } do
    uploads_dirs.map {|d| 
        run "rm -rf #{release_path}/"+d
        run "ln -nfs #{shared_path}/"+d+" #{release_path}/"+d 
      }
  end

  desc <<-EOD
    [internal] Computes uploads directory paths
    and registers them in Capistrano environment.
  EOD
  task :register_dirs do
    set :uploads_dirs, %w(uploads public/tmp_upload public/user_images public/map_images public/assets pages db/sphinx tmp)
    #set :shared_children, fetch(:shared_children) + fetch(:uploads_dirs)
  end

end




# ==============================
# Rebuilds assets
# ==============================

namespace :assets do
    desc "Packaging all assets"
    task :all do
      env = fetch :deploy_env
      run "cd #{release_path} && RAILS_ENV=#{env} nice -n 10 bundle exec rake assets:all"
    end

    desc "Launching a re-packaging of all assets in background"
    task :all_bg do
      env = fetch :deploy_env
      run "cd #{release_path} && RAILS_ENV=#{env} nohup nice -n 10 bundle exec rake assets:all > /dev/null 2>&1 &"
    end

    desc "Jammit on assets"
    task :jammit do
      env = fetch :deploy_env
      run "cd #{release_path} && RAILS_ENV=#{env} bundle exec rake assets:jammit"
      run "cd #{release_path} && RAILS_ENV=#{env} bundle exec rake assets:precompile"
      run "#{try_sudo} /etc/init.d/unicorn upgrade"
    end
end


# ====================================
# Deploy notifications through Hipchat
# ====================================
namespace :hipchat do

    desc "Notify of start of real deploy"
    task :notify_start do
      env = fetch :deploy_env
      branch = fetch :branch
      message="Starting to deploy branch #{branch} on #{env}. (@all)"
      run "curl -F 'message=#{message}' -F from=capistrano -F room_id=189959 'http://api.hipchat.com/v1/rooms/message?format=json&auth_token=844caa39fb20aafabe141dd71d3e7b'"
    end

    desc "Notify of end of deploy"
    task :notify_end do
      env = fetch :deploy_env
      branch = fetch :branch
      message="End of deploy of branch #{branch} on #{env}. (@all)"
      run "curl -F 'message=#{message}' -F from=capistrano -F room_id=189959 'http://api.hipchat.com/v1/rooms/message?format=json&auth_token=844caa39fb20aafabe141dd71d3e7b'"
    end
end


# ==============================
# Main deploy gig
# ==============================

namespace :deploy do 

    desc "Start Workers"
    task :jobs_start, :roles => :app do
      env = fetch :deploy_env
      run "cd #{release_path} && RAILS_ENV=#{env} nohup bundle exec rake jobs:start > /dev/null 2>&1"
    end

    desc "Stop Workers"
    task :jobs_stop, :roles => :app do
      env = fetch :deploy_env
      run "cd #{current_path} && RAILS_ENV=#{env} bundle exec rake jobs:stop"
    end

    task :start do ; end
    
    task :stop do ; end
    
    task :restart, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} /etc/init.d/unicorn reload"
    end
    
    desc "installs Bundler if it is not already installed"
    task :install_bundler, :roles => :app do
      run "sh -c 'if [ -z `which bundle` ];then echo Installing Bundler; sudo gem install bundler; fi'"
    end
  
    
    desc "run 'bundle install' to install Bundler's packaged gems for the current deploy"
    task :bundle_install, :roles => :app do
      run "cd #{release_path} && RAILS_ENV=#{env} && bundle install --path #{bundle_dir}"
    end

    task :migrate do
      run "cd #{release_path} && RAILS_ENV=#{env} bundle exec rake db:migrate"
    end
    
    task :updatemapcache do
      run "cd /home/diveboard/diveboard-web/current && RAILS_ENV=#{env} bundle exec rails runner script/generate_map_thumb.rb"
    end
  
    desc "remotely console"
    task :console, :roles => :app do
      input = ''
      run "cd #{current_path} && RAILS_ENV=#{env} bundle exec rails console" do |channel, stream, data|
        next if data.chomp == input.chomp || data.chomp == ''
        print data
        channel.send_data(input = $stdin.gets) if data =~ /:\d{3}:\d+(\*|>)/
      end
    end
    
    desc "Config Search"
    task :search_config, :roles => :app do
      run "cd #{release_path} && bundle exec rake ts:configure RAILS_ENV=#{env}"
    end

    desc "Start Search"
    task :search_start, :roles => :app do
      run "cd #{release_path} && bundle exec rake ts:start RAILS_ENV=#{env}"
    end

    desc "Stop Search"
    task :search_stop, :roles => :app do
      run "cd #{current_path} && bundle exec rake ts:configure RAILS_ENV=#{env}"
      run "cd #{current_path} && bundle exec rake ts:stop RAILS_ENV=#{env}"
    end

    desc "Rebuild Search"
    task :search_rebuild, :roles => :app do
      run "cd #{release_path} && bundle exec rake ts:configure RAILS_ENV=#{env}"
      run "cd #{release_path} && bundle exec rake ts:index RAILS_ENV=#{env}"
      run "cd #{release_path} && bundle exec rake ts:start RAILS_ENV=#{env}"
    end

    desc "Index Search"
    task :search_index, :roles => :app do
      run "cd #{release_path} && bundle exec rake ts:in RAILS_ENV=#{env}"
    end
    

    
    desc "Welcome robots"
    task :add_robots do
      run "cd #{release_path}/public && cp -rf robots_a.txt robots.txt"
    end
    
    desc "forbid robots to crawl"
    task :add_norobots do
      run "cd #{release_path}/public && cp -rf robots_na.txt robots.txt"
    end

    desc "prepare git archive for next pull"
    task :git_gc do
      run "cd #{release_path} && git gc"
    end

    desc "mirroring fast the prod db"
    task :mirror do
      puts "!!!!!!!!!!!!! MIRROR !!!!!!!!!!!!!!!!"
      run "cd #{release_path} && RAILS_ENV=#{env} bundle exec rails runner script/update_local_env.rb dblight"
    end
    
    desc "mirroring ALL the prod db"
    task :mirror_all do
      puts "!!!!!!!!!!!!! MIRROR ALL !!!!!!!!!!!!!!!!"
      run "cd #{release_path} && RAILS_ENV=#{env} bundle exec rails runner script/update_local_env.rb dbfull"
    end
    
    desc "Cleaning SVG cache"
    task :clean_svg_cache do
      run "cd '#{shared_path}/uploads/profiles/' && rm -f *.svg"
    end
    
    #desc " runs ln -s /var/www/blog.diveboard/ /var/www/alpha.diveboard/current/public/blog to link blog"
    #task :link_blog do
    #  run "ln -s /var/www/blog.diveboard/ #{release_path}/public/blog"
    #end

    desc "Backs up the DB before migrating"
    task :backup_db do
      run "mysqldump --lock-tables=false --user=dbuser --password=`echo $PROD_DB` diveboard > /tmp/diveboard-db-bak-#{Time.now.to_i}.sql"
    end

    task :cleanup_spots do
      run "cd #{release_path} && bundle exec rake cleanup:maintain_spots RAILS_ENV=#{env}"
    end

end
