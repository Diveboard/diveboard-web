### use cap production web:enable to enable the web from Maintenance mode
### use cap production web:disable to put the site in Maintenance mode



set :user, "diveboard"  # The server's user for deploys
server "prod.diveboard.com", :app, :web, :db, :primary => true
set :deploy_to, "/home/diveboard/diveboard-web"
set :deploy_env, 'production'
set :env, 'production'

set :branch, "master"


##must remain here -> not in deploy.rb / capistrano bug
set :bundle_gemfile,      "Gemfile"
set :bundle_dir,          fetch(:shared_path)+"/bundle"
set :bundle_flags,       "--deployment --quiet"
set :bundle_without,      [:development, :test]
##/must

set :whenever_roles, :db
set :whenever_command, "bundle exec whenever"
set :whenever_identifier, :application
set :whenever_environment, "production"
set :whenever_update_flags, "--update-crontab #{whenever_identifier} --set environment=#{whenever_environment}"
set :whenever_clear_flags, "--clear-crontab #{whenever_identifier}"

set :disable_path, "#{shared_path}/system/maintenance/"



# ==============================
# PRODUCTION SPECIFIC TASKS
# ==============================

after "deploy:restart", "git:tags:push_deploy_tag"
#after "deploy:restart", "hipchat:notify_end"
before "deploy:restart", "deploy:add_robots"
# Disable cron jobs at the begining of a deploy.
after "deploy:update_code", "whenever:clear_crontab"
# Write the new cron jobs near the end.
after "deploy:symlink", "whenever:update_crontab"
# If anything goes wrong, undo.
after "deploy:rollback", "whenever:update_crontab"
# Manage DB
before "deploy:update_code", "deploy:backup_db" # unless no_backup == 1
#before "deploy:update_code", "hipchat:notify_start"


#assets regeneration at the end... to make sure
after "deploy:jobs_start", "assets:all_bg"



# ==============================
# Cron taks handler
# ==============================
namespace :whenever do
  desc "Update application's crontab entries using Whenever"
  task :update_crontab, :roles => whenever_roles do
    # Hack by Jamis to skip a task if the role has no servers defined. http://tinyurl.com/ckjgnz
    next if find_servers_for_task(current_task).empty?
    run "cd #{current_path} && #{whenever_command} #{whenever_update_flags}"
  end

  desc "Clear application's crontab entries using Whenever"
  task :clear_crontab, :roles => whenever_roles do
    next if find_servers_for_task(current_task).empty?
    run "cd #{current_path} && #{whenever_command} #{whenever_clear_flags}"
  end
end


# ==============================
# Puts on a nice landing page during migration
# ==============================


namespace :web do
  desc "Disables the website by putting the maintenance files live."
  task :disable, :roles => :web do
    on_rollback { run "mv #{disable_path}index.html #{disable_path}index.disabled.html" }
    run "mv #{disable_path}index.disabled.html #{disable_path}index.html"
  end 
  desc "Enables the website by disabling the maintenance files."
  task :enable, :roles => :web do
      run "mv #{disable_path}index.html #{disable_path}index.disabled.html"
  end 
  desc "Copies your maintenance from public/maintenance to shared/system/maintenance."
  task :update_maintenance_page, :roles => :web do
    run "rm -rf #{shared_path}/system/maintenance/; true"
    run "cp -r #{release_path}/public/maintenance #{shared_path}/system/"
  end
end

# ==============================
# Add git tags when deploying (only prod)
# ==============================

namespace :git do

  namespace :tags do

    def tag_format(options = {})
      tag_format = ":deploy_env_:release"
      tag_format = tag_format.gsub(":deploy_env", options[:deploy_env] || deploy_env)
      tag_format = tag_format.gsub(":release",   options[:release]   || "")
      tag_format
    end

    desc "Place release tag into Git and push it to server."
    task :push_deploy_tag do
      user = `git config --get user.name`
      email = `git config --get user.email`

      run "cd #{release_path} && git tag #{tag_format(:release => release_name)} origin/master -m \"Deployed by #{user} <#{email}>\""
      run "cd #{release_path} && git push --tags"
    end

    #desc "Remove deleted release tag from Git and push it to server."
    #task :cleanup_deploy_tag do
    #      `git ls-remote --tags origin` 
    #      `git tag -d #{tag}`
    #      `git push origin :refs/tags/#{tag}`
    #end

  end

end

