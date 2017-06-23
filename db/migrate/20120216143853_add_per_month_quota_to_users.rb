class AddPerMonthQuotaToUsers < ActiveRecord::Migration
  def self.up
    change_column :users, :quota_type, "ENUM('per_dive', 'per_user', 'per_month')", :null=>false, :default=>"per_month"
    change_column :users, :quota_limit, :bigint, :null => false, :default => 500.megabyte 
    execute "UPDATE users set quota_type = 'per_month', quota_limit=#{500.megabyte} WHERE quota_type = 'per_dive'"
  end

  def self.down
    execute "UPDATE users set quota_type = 'per_dive', quota_limit=#{2048*1024} WHERE quota_type = 'per_month'"
    change_column :users, :quota_type, "ENUM('per_dive', 'per_user')", :null=>false, :default=>"per_dive"
    change_column :users, :quota_limit, :bigint, :null => false, :default => 2048*1024 
  end
end
