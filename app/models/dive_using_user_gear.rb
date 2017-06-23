class DiveUsingUserGear < ActiveRecord::Base
  belongs_to :dive
  belongs_to :user_gear

  before_save :enforce_default

  def enforce_default
    self.featured = false if self.featured.nil?
  end
end
