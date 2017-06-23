ThinkingSphinx::Index.define :spot, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 2
  indexes name
  indexes location.name, :as => :location_name
  indexes region.name, :as => :region_name
  indexes country.cname, :as => :country_name
  indexes lat
  indexes long
  has "RADIANS(spots.lat)",  :as => :latitude,  :type => :float
  has "RADIANS(spots.long)", :as => :longitude, :type => :float
  has moderate_id
  has id
  has "flag_moderate_private_to_public IS NULL", :as => :is_public, :type => :boolean
  indexes private_user_id
  set_property :latitude_attr => :latitude, :longitude_attr => :longitude
end
