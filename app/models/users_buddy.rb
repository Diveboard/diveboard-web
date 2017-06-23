class UsersBuddy < ActiveRecord::Base
  belongs_to :user
  belongs_to :buddy, :polymorphic => true

  def invite!
    return unless self.buddy.is_a? ExternalUser
    background_invite
    self.invited_at = Time.now
    self.save!
  end

  def public_dive_count
    @dive_count ||= Media::select_all_sanitized("select count(*) c from dives, dives_buddies where dives.user_id = :user_id and dives.id = dives_buddies.dive_id and dives.privacy = 0 and dives_buddies.buddy_id = :buddy_id and dives_buddies.buddy_type = :buddy_type", {:user_id => self.user_id, :buddy_id => self.buddy_id, :buddy_type => self.buddy_type}).first['c']
    return @dive_count
  end

  def all_dive_count
    @dive_count ||= Media::select_all_sanitized("select count(*) c from dives, dives_buddies where dives.user_id = :user_id and dives.id = dives_buddies.dive_id and dives_buddies.buddy_id = :buddy_id and dives_buddies.buddy_type = :buddy_type", {:user_id => self.user_id, :buddy_id => self.buddy_id, :buddy_type => self.buddy_type}).first['c']
    return @dive_count
  end


private
  def background_invite
    NotifyUser.invite_buddy(self.user,self.buddy).deliver
    self.invited_at = Time.now
    self.save!
  end
  handle_asynchronously :background_invite
end
