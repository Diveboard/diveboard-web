class Notification < ActiveRecord::Base
  extend FormatApi

  # How to create a new notification ?
  #
  #   - add a Notification.create statement wherever you like
  #   - define a few sanity checks in is_valid? (so that we don't notify of something that has been deleted)
  #   - For "What's up panel" display: create a template (_notif_xxxxxx.html.erb) in view/feeds
  #   - For instant notif, define a template and send it from send_instant_notif
  #   - For weekly notif, edit views/notify_user/digest.html and add a "when" block

  ## Transactional emails that only requires an instant email sending should not be handled here (e.g. password reinit)


  before_create :check_existing
  after_create :send_instant_notif

  belongs_to :user
  belongs_to :about, :polymorphic => true

  define_format_api :public => [:id],
    :private => [:id, :user_id, :kind, :created_at, :is_dismissed, :about_id, :about_type]

  define_api_updatable_attributes %w( dismiss )

  def is_private_for?(options={})
    return true if user.is_private_for?(options)
    Rails.logger.info options
    return false
  end

  def is_valid?
    object = self.about rescue nil
    case kind
    when 'tag_dive'
      return false unless Dive === object
      return true if object.privacy != 1 && object.db_buddy_ids.include?(user_id)
    when 'like_dive'
      return false unless Dive === object
      return true if object
    when 'comment_dive'
      return false unless Dive === object
      return true if object
    when 'like_picture'
      return false unless Picture === object
      return true if object
    when 'comment_picture'
      return false unless Picture === object
      return true if object
    when 'like_blogpost'
      return false unless BlogPost === object
      return true if object
    when 'comment_blogpost'
      return false unless BlogPost === object
      return true if object
    when 'great_picture'
      return false unless Picture === object
      return true if object && object.great_pic
    when 'reply_review'
      return false unless Review === object
      return true if object
    when 'signatureok'
      return false unless Dive === object
      return true if object
    when 'signatureko'
      return false unless Dive === object
      return true if object
    when 'dives_printed'
      return false unless User === object
      return false if param.blank?
      return true if object
    when 'shop_granted_rights'
      return false unless Shop === object
      return true if object.owners.map(&:id).include?(user_id)
    when 'dive_missing_review'
      return false unless Shop === object
      return false if object.user_proxy.nil?
      return false if Dive.where(:user_id => user.id, :shop_id => object.id).count == 0
      return true if user.review_for_shop(object).nil?
    else
      Rails.logger.warn "Unknown notification type : #{kind}"
    end
    return false
  end

  def is_dismissed?
    return !self.dismissed_at.nil?
  end

  def should_notify?
    return is_valid? && !is_dismissed?
  end

  def when
    time = Time.now - self.created_at
    if time > 3600 * 24 * 2 then
      { 'days' => (time / (3600*24)).floor() }
    elsif time > 3600 * 2 then
      { 'hours' => (time / (3600)).floor() }
    elsif time > 60 * 2 then
      { 'minutes' => (time / (60)).floor() }
    else
      { 'seconds' => time.round().to_i }
    end
  end

  def dismiss
    is_dismissed?
  end

  def dismiss=val
    self.dismissed_at = Time.now
  end

  def check_existing
    return true if self.kind == 'dives_printed'

    case kind
    when 'dive_missing_review'
      Rails.logger.debug "Making sure we don't send too many dive_missing_review notifications"
      delay_notif = 21.days
      return false if Notification.where("created_at > DATE_SUB(NOW(), INTERVAL :delay_notif SECOND) AND kind = :kind and user_id = :user_id", :kind => self.kind, :user_id => self.user_id, :delay_notif => delay_notif.to_i).count > 0
      Rails.logger.debug "Special rule for dive_missing_review"
      other = Notification.where("(dismissed_at IS NULL or dismissed_at > DATE_SUB(NOW(), INTERVAL 6 month)) AND kind = :kind AND user_id = :user_id AND about_type = :about_type AND about_id = :about_id", :kind => self.kind, :user_id => self.user_id, :about_type => self.about_type, :about_id => self.about_id)
    else
      other = Notification.where(:kind => self.kind, :user_id => self.user_id, :about_type => self.about_type, :about_id => self.about_id, :dismissed_at => nil)
    end

    Rails.logger.debug "Existing notifications to consider : #{other.inspect}"

    if other.count > 0 then
      other.each &:touch
      return false
    else
      return true
    end
  end

  def send_instant_notif

    Rails.logger.debug "Checking #{kind} for #{user.nickname} (#{user.id}) -- #{self.is_valid?}"
    return unless self.is_valid?

    Rails.logger.debug "Checking notif pref of #{user.nickname} (#{user.id}) -- #{user.accept_instant_notif_email?}"
    case kind
    when 'dives_printed' then 'OK'
    else
      return unless user.accept_instant_notif_email?
    end

    Rails.logger.debug "Notifying #{kind} for #{user.nickname} (#{user.id})"

    case kind
    when 'tag_dive'
      NotifyUser.notify_buddy_added(user, about).deliver
    when 'like_dive'
      if self.param=='google_plus'
        NotifyUser.notify_like(user, about, {"count_likes"=>false}, :dive).deliver
      else
        NotifyUser.notify_like(user, about, nil, :dive).deliver
      end
    when 'comment_dive'
      NotifyUser.notify_comment(user, about, nil, :dive).deliver
    when 'like_picture'
      if self.param=='google_plus'
        NotifyUser.notify_like(user, about, {"count_likes"=>false}, :picture).deliver
      else
        NotifyUser.notify_like(user, about, nil, :picture).deliver
      end
    when 'comment_picture'
      NotifyUser.notify_comment(user, about, nil, :picture).deliver
    when 'like_blogpost'
      if self.param=='google_plus'
        NotifyUser.notify_like(user, about, {"count_likes"=>false}, :blogpost).deliver
      else
        NotifyUser.notify_like(user, about, nil, :blogpost).deliver
      end
    when 'comment_blogpost'
      NotifyUser.notify_comment(user, about, nil, :blogpost).deliver
    when 'great_picture'
      nil
    when 'reply_review'
      nil
    when 'signatureok'
      nil
    when 'signatureko'
      nil
    when 'dives_printed'
      NotifyUser.notify_print_dives(about, param).deliver
    when 'shop_granted_rights'
      NotifyUser.notify_shop_granted(user, about).deliver
    when 'dive_missing_review'
      NotifyUser.notify_dive_misssing_review(user, about).deliver
    else
      Rails.logger.warn "Unknown notification type : #{kind}"
    end

  end
  handle_asynchronously :send_instant_notif

end
