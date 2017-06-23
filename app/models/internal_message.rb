class InternalMessage < ActiveRecord::Base
  extend FormatApi
  extend Mp
  define_shake "IM"

  default_scope includes(:to, :from, :from_group)

  belongs_to :from, :class_name => 'User', :foreign_key => :from_id
  belongs_to :from_group, :class_name => 'User', :foreign_key => :from_group_id
  belongs_to :to, :class_name => 'User', :foreign_key => :to_id
  belongs_to :in_reply_to, :polymorphic => true
  belongs_to :basket

  before_save :ensure_no_loop, :ensure_content_not_blank
  after_save :mark_replied_message_as_read
  after_create :holds_or_unhold_baskets, :notify_by_mail

  define_format_api :public => [ :id, :shaken_id, :status, :topic, :message, :from_nickname, :from_picture, :from_group_nickname, :from_group_picture, :to_nickname, :to_picture, :in_reply_to_type, :in_reply_to_id, :created_at],
    :private => []

  define_api_updatable_attributes %w(topic message status from_id to_id in_reply_to_type in_reply_to_id)
  define_api_updatable_attributes_rec 'from' => User, 'to' => User, 'from_group' => User, 'in_reply_to' => InternalMessage
  define_api_searchable_attributes %w(status topic to_id from_id from_group_id created_at)

  def is_private_for?(options={})
    return true if self.from.nil?
    return true if self.from.is_private_for?(options) rescue false
    return true if self.from_group.is_private_for?(options) rescue false
    return true if self.to.is_private_for?(options) rescue false
    return false
  end

  def is_reachable_for?(options={})
    return true if self.is_private_for?(options)
    return true if self.from.is_private_for?(options) rescue false
    return true if self.to.is_private_for?(options) rescue false
    return true if self.to_group.is_private_for?(options) rescue false
    return false
  end

  def from=user
    raise DBArgumentError.new 'Cannot change owner of existing messages' if !self.new_record?
    write_attribute(:from_id, nil) if user.nil?
    raise DBArgumentError.new 'Only admins of a group may speak for that group' if self.from_group && !self.from_group.is_private_for?(:caller => self.from)
    write_attribute(:from_id, user.id)
  end

  def from_group=user
    raise DBArgumentError.new 'Cannot change owner of existing messages' if !self.new_record?
    write_attribute(:from_group_id, nil) if user.nil?
    raise DBArgumentError.new 'Only admins of a group may speak for that group' if self.from && !user.is_private_for?(:caller => self.from)
    write_attribute(:from_group_id, user.id)
  end

  def status=val
    Rails.logger.debug "Status= #{val} from #{self.status}"
    write_attribute(:status, val)
  end

  def topic=val
    raise DBArgumentError.new 'Cannot change topic of existing messages' if !self.new_record?
    raise DBArgumentError.new "Title must have at least 3 characters" if val.blank? || val.strip.length < 3
    write_attribute(:topic, val.strip)
  end

  def message=val
    raise DBArgumentError.new 'Cannot change message of existing messages' if !self.new_record?
    raise DBArgumentError.new "Message must have at least 3 characters" if val.blank? || val.strip.length < 3
    write_attribute(:message, val.strip)
  end

  def from_nickname
    return from.nickname
  end

  def from_picture
    return from.picture
  end

  def from_group_nickname
    return from_group.nickname unless from_group.nil?
  end

  def from_group_picture
    return from_group.picture unless from_group.nil?
  end

  def to_nickname
    return to.nickname
  end

  def to_picture
    return to.picture
  end

  def ensure_no_loop
    pointer = self
    path = []
    until pointer.nil? do
      if path.include? [pointer.class.name, pointer.id]
        Rails.logger.warn "A loop attempt has been detected with #{self.class.name} #{self.id} linking to #{self.in_reply_to_type} #{self.in_reply_to_id}"
        self.in_reply_to = nil
        return
      end
      path.push [pointer.class.name, pointer.id]
      pointer = pointer.in_reply_to
      return unless pointer.respond_to? :in_reply_to
    end
  end

  def mark_replied_message_as_read
    msg = self.in_reply_to
    return if msg.nil?
    return unless msg.class == InternalMessage
    if msg.to == self.from || msg.to == self.from_group then
      msg.status = 'read'
      msg.save!
    end
  end


  #Hold or reopen pending baskets
  def holds_or_unhold_baskets
    if self.in_reply_to.is_a? Basket then
      basket = self.in_reply_to
      #if the shop sent the message, put basket 'paid' to 'hold'
      if self.from_group && self.from_group.shop_proxy_id == basket.shop_id then
        basket.hold! if self.in_reply_to.status == 'paid'
      #if the customer replied, reopen basket 'hold' to 'paid'
      elsif self.from_id == basket.user_id then
        basket.paid! if self.in_reply_to.status == 'hold'
      end
    end
  end



  def ensure_content_not_blank
    raise DBArgumentError.new "Topic must have at least 3 characters" if topic.blank? || topic.strip.length < 3
    raise DBArgumentError.new "Message must have at least 3 characters" if message.blank? || message.strip.length < 3
  end

  def permalink role
    case role
    when :shop then return "#{self.to.permalink}/care/message/#{self.shaken_id}"
    when :user then return "/settings/messages/#{self.shaken_id}"
    else raise DBArgumentError.new 'Unknown role'
    end
  end

  def fullpermalink who, option=nil
    case who
    when :to then
      root = HtmlHelper.find_root_for(option || self.to)
      role = (to.shop_proxy.nil? ? :user : :shop)
      return root.chop + permalink(role)
    when :from then
      root = HtmlHelper.find_root_for(option || self.from)
      role = (from.shop_proxy.nil? ? :user : :shop)
      return root.chop + permalink(role)
    else
      raise DBArgumentError.new 'Unknown role'
    end
  end

  def notify_by_mail
    return unless self.status == 'new'
    if self.to.shop_proxy_id.nil? then
      NotifyUser.notify_new_message(self, self.to).deliver
    else
      self.to.shop_proxy.owners.each do |owner|
        NotifyUser.notify_new_message(self, owner).deliver
      end
    end
  end

end
