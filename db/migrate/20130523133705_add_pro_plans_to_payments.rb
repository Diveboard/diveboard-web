class AddProPlansToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, 'category', :string, after: 'user_id'
    execute "update payments set category='storage'"
    change_column :payments, :category, :string, :null => false
    add_column :payments, 'subscription_plan_id', :integer, after: 'category', :default => nil
    add_column :payments, 'recurring', :boolean, after: 'amount', :default => false, :null => false
    add_column :payments, 'rec_profile_paypal', :string
    add_column :payments, 'shop_id', :integer
  end

  def self.down
    remove_column :payments, 'category'
    remove_column :payments, 'subscription_plan_id'
    remove_column :payments, 'shop_id'
    remove_column :payments, 'recurring'
    remove_column :payments, 'rec_profile_paypal'
  end
end
