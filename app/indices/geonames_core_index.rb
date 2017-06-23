ThinkingSphinx::Index.define :geonames_core, :with => :active_record do
  
  indexes name
  indexes alternatenames
  indexes latitude, :as => :lat
  indexes longitude, :as => :lng
  has "RADIANS(geonames_cores.latitude)",  :as => :latitude,  :type => :float
  has "RADIANS(geonames_cores.longitude)", :as => :longitude, :type => :float
  has id
  has population
  has country_code
  has country.id, :as => :country_id
  has "feature_code LIKE 'PPL%'", :as => :ppl, :type => :boolean
  has "feature_class LIKE 'H'", :as => :h, :type => :boolean

  set_property :latitude_attr => :latitude, :longitude_attr => :longitude

end
