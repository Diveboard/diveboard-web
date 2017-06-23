class AddQuotaToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :quota_type, "ENUM('per_dive', 'per_user')", :null=>false, :default=>"per_dive"
    add_column :users, :quota_limit, :bigint, :null => false, :default => 2048*1024 
    add_column :users, :quota_expire, :date
  end

  def self.down
    remove_column :users, :quota_type
    remove_column :users, :quota_limit
    remove_column :users, :quota_expire
  end
end
