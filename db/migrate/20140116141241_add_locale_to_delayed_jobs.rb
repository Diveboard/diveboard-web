class AddLocaleToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :locale, :string
  end

  def self.down
    remove_column :delayed_jobs, :locale
  end
end
