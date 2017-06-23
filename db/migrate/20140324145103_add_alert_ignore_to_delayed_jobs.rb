class AddAlertIgnoreToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :alert_ignore, :boolean, :default => false, :nil => false
  end
end
