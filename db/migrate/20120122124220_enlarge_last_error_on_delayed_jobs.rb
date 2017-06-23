class EnlargeLastErrorOnDelayedJobs < ActiveRecord::Migration
  def self.up
    change_column :delayed_jobs, :last_error, :text
  end

  def self.down
    change_column :delayed_jobs, :last_error, :string
  end
end
