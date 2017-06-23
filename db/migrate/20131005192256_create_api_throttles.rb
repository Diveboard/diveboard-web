class CreateApiThrottles < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE api_throttle (lookup VARCHAR(255), value INT(10), PRIMARY KEY(lookup))"
  end

  def self.down
    drop_table :api_throttle
  end
end
