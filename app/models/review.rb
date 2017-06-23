class Review < ActiveRecord::Base
  extend FormatApi
  extend Mp
  define_shake "RW"

  belongs_to :shop
  belongs_to :user
  has_many :review_votes

  before_save :update_moderate_flag

  define_format_api :public => [
          :id, :shop_id, :recommend, :mark_orga, :mark_friend, :mark_secu, :mark_boat, :mark_rent, :title, :comment, :service, :vote_up, :vote_down
        ],
        :private => [ :anonymous, :user_id, ],
        :search_light => [ ],
        :search_full => [ ]

  define_api_private_attributes :user_id

  define_api_includes :* => [:public], :search_full => [:search_light]
  define_api_searchable_attributes %w(shop_id user_id )

  define_api_updatable_attributes %w( user_id anonymous shop_id recommend mark_orga mark_friend mark_secu mark_boat mark_rent title comment service )

  def is_private_for?(options={})
    return true if options[:private]
    return true if new_record?
    return true if user.is_private_for?(options)
    return false
  end

  def self.notify_missing!
    opportunities = Media.select_all_sanitized "SELECT DISTINCT d.user_id user_id, d.shop_id shop_id
      FROM dives d left join reviews r
        ON r.user_id = d.user_id and r.shop_id = d.shop_id
      WHERE r.id is null and d.shop_id is not null
        AND d.updated_at < DATE_SUB(NOW(), INTERVAL 10 DAY)
        AND d.updated_at > DATE_SUB(NOW(), INTERVAL 180 DAY)
      ORDER BY d.time_in DESC"
    opportunities_grouped = opportunities.group_by do |couple| couple['user_id'] end
    notifications = []
    opportunities_grouped.each do |user_id, couples|
      couples.each do |couple|
        n = Notification.create :kind => 'dive_missing_review', :user_id => couple['user_id'], :about_type => 'Shop', :about_id => couple['shop_id']
        notifications.push(n) and break if !n.id.nil?
      end
    end
    return notifications
  end

  def average_mark
    sum = 0.0
    count = 0
    [:mark_orga, :mark_friend, :mark_secu, :mark_boat, :mark_rent].each do |mark_attr_name|
      val = read_attribute(mark_attr_name)
      if !val.nil? then
        sum += val
        count += 1
      end
    end

    if count > 0 then
      if recommend then
        return sum/count
      else
        return 0.7*sum/count
      end
    else
      if recommend then
        return 4
      else
        return 2
      end
    end
  end

  def vote_up
    review_votes.where(vote: true).count
  end

  def vote_down
    review_votes.where(vote: false).count
  end

  def update_moderate_flag
    self.flag_moderate = true if (self.changed_attributes.keys & ['comment', 'title']).length > 0
  end

  def reply=val
    val = nil if val.blank?
    Notification.create :kind => 'reply_review', :user_id => self.user_id, :about_type => 'Review', :about_id => self.id
    write_attribute(:reply, val)
  end

end
