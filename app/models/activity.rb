class Activity < ActiveRecord::Base
  belongs_to :dive
  belongs_to :picture
  belongs_to :user
  belongs_to :spot

  def feeds
    ActivityFeed.list_for_activity(self.id)
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
end
