class Tag < ActiveRecord::Base

  belongs_to :user

  DEFAULT_URL = ROOT_URL

  def redirect_url
    return user.fullpermalink(:canonical) unless user.nil?
    return url unless url.blank?
    DEFAULT_URL
  end


  def permalink
    "/tag/#{shaken_id}"
  end

  def fullpermalink option=nil
    HtmlHelper.find_root_for(option).chop+permalink
  end

  def shaken_id
    Mp.shake(self.id)
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    return Mp.deshake(code)
  end

end
