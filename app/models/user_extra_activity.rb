class UserExtraActivity < ActiveRecord::Base
  belongs_to :user
  belongs_to :geonames_core, foreign_key: :geoname_id
end
