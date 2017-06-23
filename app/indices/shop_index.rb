ThinkingSphinx::Index.define :shop, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 2
  indexes name
  indexes country.cname, :as => :country_name
  indexes city
  has "flag_moderate_private_to_public IS NULL", :as => :is_public, :type => :boolean
  has "flag_moderate_private_to_public=false AND private_user_id IS NULL", :as => :is_disabled, :type => :boolean
  has "RADIANS(shops.lat)", :as => :latitude,  :type => :float
  has "RADIANS(shops.lng)", :as => :longitude, :type => :float
end
