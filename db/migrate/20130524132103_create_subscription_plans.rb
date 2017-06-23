class CreateSubscriptionPlans < ActiveRecord::Migration
  def self.up
    create_table :subscription_plans do |t|
      t.string 'category', :null => false
      t.string 'name', :null => false
      t.string 'title', :null => false
      t.string 'option_name', :default => true
      t.string 'option_title', :default => true
      t.boolean 'available', :null => false, :default => true
      t.boolean 'preferred', :null => false, :default => false
      t.float 'price', :default => nil, :precision => 5, :scale => 2
      t.text 'commercial_note', :default => nil
      t.timestamps
    end
    Media.insert_bulk_sanitized 'subscription_plans', [
      {category: 'plan_pro', name: 'free', title: 'Starter', option_name:nil, option_title:nil, available: true, preferred:true, price: nil, commercial_note: nil},
      {category: 'plan_pro', name: 'premium', title: 'Premium', option_name:'Monthly subscription', option_title: 'monthly', available: true, preferred:false, price: 50, commercial_note: nil},
      {category: 'plan_pro', name: 'premium', title: 'Premium', option_name:'Yearly subscription', option_title: 'yearly', available: true, preferred:true, price: 500, commercial_note: 'Get 2 months free!'}
    ]
  end

  def self.down
    drop_table :subscription_plans
  end
end
