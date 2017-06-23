class ChangeFbidType < ActiveRecord::Migration
  def self.up
    change_column :users, :fb_id, :bigint
    change_column :users, :id, :bigint

  end

  def self.down
    change_column :users, :fb_id, :int
    change_column :users, :id, :int
  end
end
