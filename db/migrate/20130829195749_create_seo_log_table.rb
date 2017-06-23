class CreateSeoLogTable < ActiveRecord::Migration
  def self.up
    execute "create table seo_logs (lookup VARCHAR(255), date datetime, idx INTEGER, url VARCHAR(255), other text)"
  end

  def self.down
    execute "drop table seo_logs"
  end
end
