class AddIndexesOnSeoLogs < ActiveRecord::Migration
  def up
    add_index :seo_logs, :lookup
    add_index :seo_logs, :date
  end

  def down
    remove_index :seo_logs, :lookup
    remove_index :seo_logs, :date
  end
end
