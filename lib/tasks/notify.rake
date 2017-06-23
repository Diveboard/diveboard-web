namespace :email_notify do

  desc "Email shops that they have a new message waiting for them"
  task :new_message_for_shops => :environment do |t, args|
    ## 1. list all shops that should be notified
    ## there is signature waiting
    shops_list = Signature.where(:rejected => false).where(:signed_date => nil).where(:notified_at => nil).where(:signby_type => "Shop").where("signby_id !=0").map(&:signby).uniq
    ## we don't want to add messages as user must have already been notified
    exit_status = 0
    shops_list.each do |s|
      begin
        next if s.status != :public
        next if s.email.nil? || s.email.match(/\@diveboard.com$/)
        Rails.logger.debug  "Notifying shop #{s.id} that he has pending actions"
        NotifyShop.notify_daily_action(s).deliver
        Signature.where(:rejected => false).where(:signed_date => nil).where(:notified_at => nil).where(:signby_type => "Shop").where(:signby_id => s.id).each do |si|
          Rails.logger.debug  "Marking signature action #{si.id} as notified"
          si.notified_at = Time.now
          si.save
        end
      rescue
        puts  "Could not Notify shop #{s.id} that he has pending actions because #{$!.message}"
        puts  $!.backtrace
        exit_status = 1
      end
    end

    raise DBArgumentError.new "Task performed with errors" if exit_status > 0

  end

  desc "Generate en export file for public shops for mailchimp"
  task :export_shop_contacts => :environment do |t, args|
    user_id = "*"
    File.open("/tmp/public_shops.csv", 'w') {|f| 
    Shop.all.each do |e|
      next if e.user_proxy.nil?
      group = e.user_proxy
      salt = rand(100000)
      if !e.is_claimed?
        sign = ShopClaimHelper.generate_signature_claim(user_id, group.id, salt)
        claim = (group.fullpermalink(:canonical)+"?valid_claim=#{salt}_#{user_id}_#{group.id}_#{sign}")
      else
        claim = ""
      end
      s= "#{e.name},#{e.email},#{e.country.ccode rescue "n/a"},#{e.fullpermalink(:canonical)},#{e.is_claimed?},#{claim},#{e.dives.length},#{e.reviews.length}\n"
      f.write s
    end
    }
    puts "/tmp/public_shops.csv has been generated"
  end


  desc "Generating digests for 1/14 of users"
  task :send_digests => :environment do |t, args|
    User.where(shop_proxy_id: nil).where("(id%14) = :modulus", modulus: ((Time.now.to_i % 14.days) / 1.day)).find_each do |user|
      begin
        NotifyUser.digest(user).deliver
      rescue DBArgumentError => e
        Rails.logger.debug "Not notifying digest to user #{user.id}: #{$!.message}"
      rescue
        Rails.logger.error "Error while notifying digest to user #{user.id}: #{$!.message}"
        Rails.logger.debug $!.backtrace.join "\n"
      end
    end
  end


end
