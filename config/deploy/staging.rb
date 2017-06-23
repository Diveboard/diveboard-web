####
#### to deploy a different branch on staging use the command :
####    cap staging deploy -S branch=profile_db_change
####
set :deploy_to, "/home/diveboard/diveboard-web"
set :deploy_env, "staging"
set :env, "staging"
set :user, "diveboard"
server "stage.diveboard.com", :app, :web, :db, :primary => true


##must remain here -> not in deploy.rb / capistrano bug
set :bundle_gemfile,      "Gemfile"
set :bundle_dir,          fetch(:shared_path)+"/bundle"
set :bundle_flags,       "--deployment --quiet"
set :bundle_without,      [:development, :test]
##/must

##STAGING-SPECIFIC TASKS
before "deploy:restart", "deploy:add_norobots"
if db == "full"
  before "deploy:restart", "deploy:mirror_all"
elsif  db == "light"
  before "deploy:restart", "deploy:mirror"
end
after "uploads:symlink", "deploy:clean_svg_cache"


set :branch, "staging" unless exists?(:branch)
