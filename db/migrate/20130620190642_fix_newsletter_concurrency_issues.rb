class FixNewsletterConcurrencyIssues < ActiveRecord::Migration
  def self.up
    add_column :newsletters, :sending_pid, :integer
    execute "UPDATE delayed_jobs set queue = 'default'"
  end

  def self.down
    remove_column :newsletters, :sending_pid
    execute "UPDATE delayed_jobs set queue = NULL"
  end
end
