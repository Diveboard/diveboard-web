class NewsletterUser < ActiveRecord::Base
  belongs_to :recipient, :polymorphic => true
  belongs_to :newsletter
end
