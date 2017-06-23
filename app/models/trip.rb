class Trip < ActiveRecord::Base
  has_many :dives, :class_name => 'Dive'
  belongs_to :user

  def permalink
    url_name = name.to_url rescue nil
    url_name = "trip" if url_name.blank?
    return user.permalink+"/trip/" + self.id.to_s + "-" + url_name
  end

  def fullpermalink(option=nil)
    HtmlHelper.find_root_for(option).chop+permalink
  end
end
