namespace :purge do
  desc "Purging ghosts objects on cloud"
  task :ghosts => :environment do |t, args|
    errors = []
    count = 0
    client = GoogleStorage::Client.new

    Rails.application.config.google_cloud_buckets.values.flatten.uniq.each do |bucket|
      purge_list = CloudObject.ghosts(bucket)[:missing]
      purge_list_count = purge_list.count
      Rails.logger.info "#{purge_list.count} ghost elements in cloud to purge in bucket #{bucket}"
      puts "#{purge_list.length} ghost elements in cloud to purge in bucket #{bucket}"
      purge_list.each do |obj|
        begin
          count += 1
          client.delete_object(bucket, obj['Key'])
          Rails.logger.info "Object '#{obj['Key']} deleted from the cloud bucket '#{bucket}'"
          puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - Purge : #{count}/#{purge_list_count}" if count % 500 == 0
        rescue
          Rails.logger.error "Error while deletin cloud object #{obj['Key']} : #{$!.message}"
          Rails.logger.debug $!.backtrace
          errors.push $!
        end
      end
    end

    if errors.length == 0 then
      Rails.logger.info "All cloud orphans have been purged : #{count} elements deleted"
      puts "All cloud orphans have been purged : #{count} elements deleted"
    else
      Rails.logger.error "Errors happened while purging cloud orphans (#{errors.length} fails over #{count})"
      puts "Errors happened while purging cloud orphans (#{errors.length} fails over #{count})"
    end
  end

  desc "Purging orphans objects on cloud"
  task :cloud => :environment do |t, args|
    errors = []
    count = 0

    purge_list = CloudObject.orphans
    purge_list_count = purge_list.count
    Rails.logger.info "#{purge_list.count} cloud orphans to purge"
    puts "#{purge_list.count} cloud orphans to purge"
    purge_list.each do |obj|
      begin
        count += 1
        obj.destroy
        puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - Purge : #{count}/#{purge_list_count}" if count % 500 == 0
      rescue
        Rails.logger.error "Error while purging cloud object #{obj.id} : #{$!.message}"
        Rails.logger.debug $!.backtrace
        errors.push $!
      end
    end

    if errors.length == 0 then
      Rails.logger.info "All cloud orphans have been purged : #{count} elements deleted"
      puts "All cloud orphans have been purged : #{count} elements deleted"
    else
      Rails.logger.error "Errors happened while purging cloud orphans (#{errors.length} fails over #{count})"
      puts "Errors happened while purging cloud orphans (#{errors.length} fails over #{count})"
    end
  end


  desc "Purging orphans pictures older than a day"
  task :pictures => :environment do |t, args|
    errors = []
    count = 0

    Picture.orphans.each do |pic|
      begin
        next if pic.created_at+1.day > Time.now
        count += 1
        pic.destroy
      rescue
        Rails.logger.error "Error while purging picture #{pic.id} : #{$!.message}"
        Rails.logger.debug $!.backtrace
        errors.push $!
      end
    end

    if errors.length == 0 then
      Rails.logger.info "All cloud orphans have been purged : #{count} elements deleted"
      puts "All cloud orphans have been purged : #{count} elements deleted"
    else
      Rails.logger.error "Errors happened while purging picture orphans (#{errors.length} fails over #{count})"
      puts "Errors happened while purging picture orphans (#{errors.length} fails over #{count})"
    end

  end

  desc "Purging all orphans pictures"
  task :pictures_nolimit => :environment do |t, args|
    errors = []
    count = 0

    Picture.orphans.each do |pic|
      begin
        count += 1
        pic.destroy
      rescue
        Rails.logger.error "Error while purging picture #{pic.id} : #{$!.message}"
        Rails.logger.debug $!.backtrace
        errors.push $!
      end
    end

    if errors.length == 0 then
      Rails.logger.info "All cloud orphans have been purged : #{count} elements deleted"
      puts "All cloud orphans have been purged : #{count} elements deleted"
    else
      Rails.logger.error "Errors happened while purging picture orphans (#{errors.length} fails over #{count})"
      puts "Errors happened while purging picture orphans (#{errors.length} fails over #{count})"
    end

  end

  desc "Purging the db of old data"
  task :db => :environment do |t,args|
    ["purge:user_sessions", "purge:user_auth_tokens", "purge:activities"].each do |t|
      Rake::Task[t].execute
    end
  end

  desc "Purging sessions which haven't been used for more than 60 days"
  task :user_sessions => :environment do |t, args|
    Rails.logger.info "Starting purge of sessions"
    nb_rows_per_call = 50000
    nb_call = 0
    numrows = nb_rows_per_call
    while numrows >= nb_rows_per_call && nb_call < 100 do
      nb_call += 1
      numrows = ActiveRecord::Base.connection.delete("DELETE FROM sessions WHERE updated_at < DATE_SUB(NOW(), INTERVAL 60 day) limit #{nb_rows_per_call}")
      Rails.logger.info "Purged #{numrows} from sessions"
    end
  end

  desc "Purging expired AuthTokens which have expired more than 30 days ago"
  task :user_auth_tokens => :environment do |t, args|
    Rails.logger.info "Starting purge of auth_tokens"
    nb_rows_per_call = 50000
    numrows = nb_rows_per_call
    nb_call = 0
    while numrows >= nb_rows_per_call && nb_call < 100 do
      nb_call += 1
      numrows = ActiveRecord::Base.connection.delete("DELETE FROM auth_tokens WHERE expires < DATE_SUB(NOW(), INTERVAL 60 day) limit #{nb_rows_per_call}")
      Rails.logger.info "Purged #{numrows} from auth_tokens"
    end
  end


  desc "Purging old activities"
  task :activities => :environment do |t, args|
    Rails.logger.info "Starting purge of activities"
    nb_rows_per_call = 50000
    numrows = nb_rows_per_call
    nb_call = 0
    while numrows >= nb_rows_per_call && nb_call < 100 do
      nb_call += 1
      numrows = ActiveRecord::Base.connection.delete("DELETE from activities where date_add(created_at, interval 3 MONTH) < NOW() limit #{nb_rows_per_call}")
      Rails.logger.info "Purged #{numrows} from auth_tokens"
    end
  end

end
