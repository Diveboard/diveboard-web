class ActivityFollowing < ActiveRecord::Base

  after_save :clear_cache_feed!
  before_destroy :clear_cache_feed!

  def clear_cache_feed!
    I18n.available_locales.each do |locale|
      begin ActionController::Base.new.expire_fragment "#{locale} user_#{self.follower_id}_feed" rescue nil end unless self.follower_id.nil?
      begin ActionController::Base.new.expire_fragment "#{locale} user_#{self.follower_id}_feed_config" rescue nil end unless self.follower_id.nil?
    end
  end

end
