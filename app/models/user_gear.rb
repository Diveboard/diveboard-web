
class UserGear < ActiveRecord::Base
  extend FormatApi

  belongs_to :user
  has_many :dive_using_user_gears
  has_many :dives, :through => :dive_using_user_gears, :source => 'dive'

  attr_accessor :featured, :featured_within

  before_destroy {|record|
                    record.dive_using_user_gears.destroy
                 }

  define_format_api :public => [:category, :id, :manufacturer, :model, :featured, :class => 'UserGear'],
                    :private =>  [:acquisition, :category, :id, :last_revision, :manufacturer, :model, :reference, :featured, :auto_feature, :class => 'UserGear']

  define_api_private_attributes :reference, :auto_feature, :acquisition, :last_revision

  define_api_updatable_attributes %w( category manufacturer model featured acquisition last_revision reference auto_feature user_id) ###TODO remove user_id

  def is_private_for?(options={})
    return true if self.user_id.nil?
    return true if options[:caller].id == self.user_id rescue false
    return true if self.user.is_private_for?(options) rescue false
    return false
  end

  def total_usage
    DiveUsingUserGear.where(:user_gear_id => self.id).select('distinct dive_id').count
  end

  def revised_usage
    return nil if self.last_revision.nil?
    Dive.joins(:dive_using_user_gears).where('time_in > :rdate and user_gear_id = :gid', {:rdate => self.last_revision, :gid => self.id}).select('distinct dives.id').count
  end
end

