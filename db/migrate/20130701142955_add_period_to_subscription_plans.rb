class AddPeriodToSubscriptionPlans < ActiveRecord::Migration
  def self.up
    add_column :subscription_plans, :period, :integer, :null => false, :default => 1, :after => :option_title
    execute "update subscription_plans set period = 12 where option_name = 'yearly'"
  end

  def self.down
    remove_column :subscription_plans, :period
  end
end
