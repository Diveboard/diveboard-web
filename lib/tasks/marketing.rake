namespace :email_marketing do

  desc "Email shops to ask them to confirm their data"
  task :onboarding => :environment do |t, args|
    exit_status = 0

    Shop.where(:flag_moderate_private_to_public => nil).each do |e|
      if begin e.created_at > 1.week.ago rescue false end
        puts "Shop #{e.id} is too young, will bug him later"
        next
      end

      begin
        sent_emails = e.emails_marketing.map(&:content)
        
        last_email_date = begin e.emails_marketing.order {|e,f| e.created_at <=> f.created_at} .last.created_at rescue Time.at(0) end
        if last_email_date > 1.week.ago
          puts "Shop #{e.id} was bugged over the last week already"
          next
        end

        ##marketing stream
        if !sent_emails.include?("marketing_shop_onboarding-check_info") && !e.is_claimed?
          ##let's try and make it claimed
          MarketingMailer.shop_check_info(e).deliver
          puts "Email email_marketing:check_info sent to shop #{e.id}"
        elsif !sent_emails.include?("marketing_shop_onboarding-ask_fb_reviews") &&  e.reviews.count < 3
          ##let's try and grab their users
          MarketingMailer.shop_ask_fb_reviews(e).deliver
          puts "Email email_marketing:ask_fb_reviews sent to shop #{e.id}"
        elsif !sent_emails.include?("marketing_shop_onboarding-online_bookings") &&  e.paypal_id.nil?
          ##let's try and grab their users
          MarketingMailer.shop_online_bookings(e).deliver
          puts "Email email_marketing:shop_online_bookings sent to shop #{e.id}"
        else 
          puts "Shop #{e.id} got all available marketing emails !"
        end


      rescue
        puts "Could not deliver email email_marketing:check_info to shop #{e.id}: #{$!.message}"
        exit_status = 1
      end
    end
    ExternalUser.where("user_id is null").group("email").reject {|e| e.email.nil? || e.users_buddies.empty?} .reject{|e| !User.find_by_email(e.email).nil? || !User.find_by_contact_email(e.email).nil?} .each do |e|
      ##asking external users to join
      begin
        sent_emails = e.emails_marketing.map(&:content)
        
        last_email_date = begin e.emails_marketing.order {|e,f| e.created_at <=> f.created_at} .last.created_at rescue Time.at(0) end
        if last_email_date > 1.week.ago
          puts "ExternalUser #{e.id} was bugged over the last week already"
          next
        end

        ##marketing stream
        if !sent_emails.include?("marketing_external_user_transform-join")
          ##let's try and make it claimed
          MarketingMailer.external_user_join(e).deliver
          puts "Email email_marketing:external_user_join sent to ExternalUser #{e.id}"
        else 
          puts "ExternalUser #{e.id} got all available marketing emails !"
        end
      rescue
        puts "Could not deliver email email_marketing:external_user_join to ExternalUser #{e.id}: #{$!.message}"
        exit_status = 1
      end
    end

    
    User.where("shop_proxy_id is null").each do |e|
      begin
        sent_emails = e.emails_marketing.map(&:content)
        
        last_email_date = begin e.emails_marketing.order {|e,f| e.created_at <=> f.created_at} .last.created_at rescue Time.at(0) end
        if last_email_date > 1.week.ago
          puts "User #{e.id} was bugged over the last week already"
          next
        end

        ##marketing stream
        if e.dives.count >1 && e.created_at < 3.days.ago && !sent_emails.include?("marketing_internal_user-reffer_simple")
          ##let's try and make it claimed
          MarketingMailer.user_reffer_friends(e).deliver
          puts "Email email_marketing:user_reffer_friends sent to User #{e.id}"
        else 
          puts "User #{e.id} got all available marketing emails !"
        end
      rescue
        puts "Could not deliver email email_marketing:user_reffer_friends to User #{e.id}: #{$!.message}"
        exit_status = 1
      end
    end
    
    raise DBArgumentError.new "Task performed with errors" if exit_status > 0
  end
end
    
