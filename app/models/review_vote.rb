class ReviewVote < ActiveRecord::Base
  extend FormatApi
  belongs_to :user
  belongs_to :review

  define_format_api :public => [:user_id, :review_id, :vote]
  define_api_private_attributes :user_id
  define_api_updatable_attributes %w( user_id review_id vote )

  def is_private_for?(options={})
    return true if self.user_id.nil?
    return true if options[:caller].id == self.user_id rescue false
    return false
  end

end