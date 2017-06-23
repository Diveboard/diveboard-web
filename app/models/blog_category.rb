class BlogCategory < ActiveRecord::Base
  has_many :blog_posts
  before_save :update_blob

   def permalink
    "/community/#{self.blob}"
  end

  def update_blob
    begin
      self.blob = self.name.to_url
    rescue
      self.blob = "category"
    end
  end

  def fullpermalink *options
    HtmlHelper.find_root_for(*options).chop + permalink
  end
end