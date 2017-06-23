
namespace :cache do

  desc "Updating homepage cahed fragments"
  task :homepage  => :environment do |t, args|
    I18n.available_locales.each do |locale|
      I18n.locale = locale
      (0..9).each do |version|
        app = ActionDispatch::Integration::Session.new Rails.application
        code = app.get "/?cache_version=#{version}&locale=#{locale}"
        raise DBTechnicalError.new "Error while caching homepage" if code != 200
      end
    end
  end

  desc "Updating charts page"
  task :charts  => :environment do |t, args|
    c = AdminController.new
    r = ActionDispatch::Request.new 'rack.input' => ''
    c.request = r
    c.render_to_string 'charts', :locals => {:cookies => {}, :params => {:force_refresh => true}}, :layout => false
  end


  desc "Updating scores in database"
  task :scores => :environment do |t, args|
    previous_val = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false
    previous_level = Rails.logger.level
    Rails.logger.level = 1
    filter_id = Time.now.days_to_week_start
    Shop.where("id % 7 = #{filter_id}").find_in_batches(batch_size: 300, include: [:reviews, :dives, :good_to_sell, :user_proxy => :group_memberships]) do |shops|
      shops.each do |shop|
        begin
          initial_score = shop.score
          shop.compute_score
          shop.save if shop.score != initial_score
        rescue
          Rails.logger.warn("Exception in #{caller[0].gsub(/.*\//, '')}: #{$!.message}") and Rails.logger.debug($!.backtrace.join "\n")
        end
      end
    end
    Dive.where("id % 7 = #{filter_id}").find_in_batches(batch_size: 300, include: [:picture_album_pictures, :shop, :spot]) do |dives|
      dives.each do |dive|
        begin
          initial_score = dive.score
          new_score = dive.compute_score
          dive.save if new_score != initial_score
        rescue
          Rails.logger.warn("Exception in #{caller[0].gsub(/.*\//, '')}: #{$!.message}") and Rails.logger.debug($!.backtrace.join "\n")
        end
      end
    end
    Spot.where("id % 7 = #{filter_id}").find_in_batches(batch_size: 300, include: [:dives]) do |spots|
      spots.each do |spot|
        spot.update_score! rescue Rails.logger.warn("Exception in #{caller[0].gsub(/.*\//, '')}: #{$!.message}") and Rails.logger.debug($!.backtrace.join "\n")
      end
    end
    Rails.logger.level = previous_level
    Delayed::Worker.delay_jobs = previous_val
  end

  desc "Updating best pictures in database"
  task :best_pics => :environment do |t, args|
    Country.find_each &:update_best_pics!
    Spot.find_each &:update_best_pics!
  end

end

