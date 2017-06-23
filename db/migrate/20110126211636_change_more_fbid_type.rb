class ChangeMoreFbidType < ActiveRecord::Migration
  def self.up
    change_column :dives, :user_id, :bigint
  end

  def self.down
    change_column :dives, :user_id, :int
  end
end
