namespace :shops do
  desc "Validate a user's claim to a shop"
  task :validate_claim  => :environment do |t, params|
    begin 
      args = ShopClaimHelper.check_claim_user(params[0])
      if Membership.where({:user_id => args[:user].id, :group_id => args[:group].id, :role => 'admin'}).count == 0 then
        Membership.create :user_id => args[:user].id, :group_id => args[:group].id, :role => 'admin'
        Notification.create :kind => 'shop_granted_rights', :user_id => args[:user].id, :about => args[:group].shop_proxy
      end
      puts "claim validated"
    rescue
      puts  "Could not validate claim"
      puts  $!.backtrace
      exit_status = 1
    end
  end
end