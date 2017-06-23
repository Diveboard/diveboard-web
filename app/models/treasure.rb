class Treasure < ActiveRecord::Base
  attr_accessible :campaign_name, :object_id, :object_type, :user_id

  belongs_to :user
 
end
