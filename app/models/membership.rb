class Membership < ActiveRecord::Base
  extend FormatApi

  belongs_to :user
  belongs_to :group, :class_name => 'User', :foreign_key => :group_id

  before_update :ensure_unicity
  before_create :ensure_unicity

  define_format_api :public => [
          :id, :user_id, :group_id, :role
        ]

  define_api_private_attributes :user_id, :group_id, :role, :id
  define_api_includes :* => [:public]
  define_api_check_end_state true

  define_api_updatable_attributes %w(group_id user_id role)

  def is_private_for?(options={})
    return true if options[:private]
    return true if self.group.nil?
    return true if !self.group.nil? && self.group.is_private_for?(options)
    return false
  end

  def is_accessible_for?(options={})
    is_private_for?(options) || self.user.is_private_for?(options)
  end

  def group_id=val
    raise DBArgumentError.new "Not possible to change group_id on Membership once set" unless self.group_id.nil?
    write_attribute(:group_id, User.fromshake(val).id)
  end

  def user_id=val
    raise DBArgumentError.new "Not possible to change user_id on Membership once set" unless self.user_id.nil?
    write_attribute(:user_id, User.fromshake(val).id)
  end

private

  def ensure_unicity
    others = Membership.where(:user_id => self.user_id, :group_id => self.group_id)
    others = others.where("id <> #{self.id}") unless self.id.nil?
    raise DBArgumentError.new "Membership already exists" if others.count > 0
  end

end
