class DivesBuddy < ActiveRecord::Base
  belongs_to :dive, :inverse_of => :dives_buddies
  belongs_to :buddy, :polymorphic => true

  after_create :add_to_user_buddies

  def add_to_user_buddies
    UsersBuddy.create :user_id => dive.user_id, :buddy_type => buddy_type, :buddy_id => buddy_id
  end
end
