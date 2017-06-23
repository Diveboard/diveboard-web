### USE cap staging deploy:updatedb to update the test database from production this will NOT update the fish db

###TO deploy a given branch do : 
###cap -S branch="profile_db_change" staging deploy


# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :user, "alex"  # The server's user for deploys
#set :scm_passphrase, "p@ssw0rd"  # The deploy user's password
default_run_options[:pty] = true 
ssh_options[:forward_agent] = true
set :deploy_to, "/home/alex/diveboard"
set :use_sudo, false
set :deploy_env, 'staging'



set :default_environment, {
    'PATH' => '/var/lib/gems/1.9.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
}


set :bundle_gemfile,      "Gemfile"
  set :bundle_dir,          fetch(:shared_path)+"/bundle"
  set :bundle_flags,       "--deployment --quiet"
  set :bundle_without,      [:development, :test]


role :web, "test.diveboard.com"                          # Your HTTP server, Apache/etc
role :app, "test.diveboard.com"                          # This may be the same as your `Web` server
role :db,  "test.diveboard.com", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

before "deploy:bundle_install", "deploy:install_bundler"
before "deploy:update_code", "deploy:search_stop"
after "deploy:update_code", "deploy:bundle_install"


##TODO before restart : do the sphinx danse
before "deploy:restart", "deploy:add_norobots"
after "deploy:restart", "deploy:migrate"
#before "deploy:migrate", "deploy:mirror_all"
before "deploy:migrate", "deploy:mirror"


after "deploy:finalize_update", "uploads:symlink"
after "uploads:symlink", "deploy:clean_svg_cache"

after "deploy:bundle_install", "deploy:copy_sphinx"

### WARNING !!!! should be AFTER !!!
after "deploy:migrate", "deploy:search_rebuild"
on :start, "uploads:register_dirs"
after "uploads:register_dirs", "uploads:setup"


namespace :deploy do
  
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  desc "installs Bundler if it is not already installed"
  task :install_bundler, :roles => :app do
    run "sh -c 'if [ -z `which bundle` ];then echo Installing Bundler; sudo gem install bundler; fi'"
  end

    desc "run 'bundle install' to install Bundler's packaged gems for the current deploy"
    task :bundle_install, :roles => :app do
      run "cd #{release_path} && RAILS_ENV=staging && bundle install --path #{bundle_dir}"
    end

    task :migrate do
      run "cd #{current_path} && RAILS_ENV=staging bundle exec rake db:migrate"
    end
    
    task :correct_spots do
      run "cd #{current_path} && RAILS_ENV=staging bundle exec rails runner script/spot_precision_correct.rb"
    end
    
    task :mirror do
      #run "cd #{current_path} && RAILS_ENV=staging bundle exec rails runner script/generate_map_thumb.rb"
      run "rm -rf /tmp/diveboard.sql"
      run "mysqldump --user=dbuser --password='VZfs591bnw32d' --ignore-table=diveboard.fishes  --ignore-table=diveboard.eolcnames  --ignore-table=diveboard.eolsnames --ignore-table=diveboard.geonames_cores --ignore-table=diveboard.geonames_countries --ignore-table=diveboard.geonames_featurecodes diveboard > /tmp/diveboard.sql"
      #run "mysqldump --user=dbuser --password='VZfs591bnw32d' diveboard > /tmp/diveboard.sql"
      run "echo 'show tables' | mysql -s --user=dbusertest --password='TkVvfuqxkxc97FzGjrPPokpYUu'  diveboard_test |  grep -Ev '^(fishes|eolcnames|eolsnames|geonames)\$' | sed 's/.*/DROP TABLE \\0;/' | mysql -s --user=dbusertest --password='TkVvfuqxkxc97FzGjrPPokpYUu'  diveboard_test"
      run "mysql --user=dbusertest --password='TkVvfuqxkxc97FzGjrPPokpYUu'  diveboard_test < /tmp/diveboard.sql"
      run "cp -rf /var/www/alpha.diveboard/shared/public/* #{shared_path}/public/"
    end
    
    task :mirror_all do
      #run "cd #{current_path} && RAILS_ENV=staging bundle exec rails runner script/generate_map_thumb.rb"
      run "rm -rf /tmp/diveboard.sql"
      #run "mysqldump --user=dbuser --password='VZfs591bnw32d' --ignore-table=diveboard.fishes  --ignore-table=diveboard.eolcnames  --ignore-table=diveboard.eolsnames diveboard > /tmp/diveboard.sql"
      run "mysqldump --user=dbuser --password='VZfs591bnw32d' diveboard > /tmp/diveboard.sql"
      ## errase the stage db
      run "mysqldump -udbusertest -p'TkVvfuqxkxc97FzGjrPPokpYUu' --add-drop-table --no-data diveboard_test | grep ^DROP | mysql -udbusertest -p'TkVvfuqxkxc97FzGjrPPokpYUu' diveboard_test"
      ## imports the data
      run "mysql --user=dbusertest --password='TkVvfuqxkxc97FzGjrPPokpYUu'  diveboard_test < /tmp/diveboard.sql"
      run "cp -rf /var/www/alpha.diveboard/shared/public/* #{shared_path}/public/"
    end
    
    task :add_norobots do
      run "cd #{current_path}/public && cp -rf robots_na.txt robots.txt"
    end
    
  
    desc "remotely console"
    task :console, :roles => :app do
      input = ''
      run "cd #{current_path} && RAILS_ENV=staging rails console" do |channel, stream, data|
        next if data.chomp == input.chomp || data.chomp == ''
        print data
        channel.send_data(input = $stdin.gets) if data =~ /:\d{3}:\d+(\*|>)/
      end
    end

    desc "Config Search"
    task :search_config, :roles => :app do
      run "cd #{release_path} && rake ts:configure RAILS_ENV=staging"
    end

    desc "Start Search"
    task :search_start, :roles => :app do
      run "cd #{current_path} && rake ts:start RAILS_ENV=staging"
    end

    desc "Stop Search"
    task :search_stop, :roles => :app do
      run "cd #{current_path} && rake ts:stop RAILS_ENV=staging"
    end

    desc "Rebuild Search"
    task :search_rebuild, :roles => :app do
      run "cd #{current_path} && rake ts:stop RAILS_ENV=staging"
      run "cd #{current_path} && rake ts:configure RAILS_ENV=staging"
      run "cd #{current_path} && rake ts:index RAILS_ENV=staging"
      run "cd #{current_path} && rake ts:start RAILS_ENV=staging"
    end

    desc "Index Search"
    task :search_index, :roles => :app do
      run "cd #{current_path} && rake ts:in RAILS_ENV=staging"
    end

    desc "Re-establish symlinks"
    task :copy_sphinx do
      run <<-CMD
        mkdir -p #{shared_path}/db/sphinx &&
        rm -rf #{release_path}/db/sphinx &&
        ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx 
      CMD
    end

    desc "Cleaning SVG cache"
    task :clean_svg_cache do
      run "cd '#{shared_path}/uploads/profiles/' && rm -f *.svg"
    end
  
end
