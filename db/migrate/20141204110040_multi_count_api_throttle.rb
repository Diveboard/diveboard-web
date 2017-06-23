class MultiCountApiThrottle < ActiveRecord::Migration
  def up
    rename_column :api_throttle, :value, :count_noauth
    add_column :api_throttle, :count_auth, :integer, nil: false, default: 0
  end

  def down
    remove_column :api_throttle, :count_auth
    rename_column :api_throttle, :count_noauth, :value
  end
end
