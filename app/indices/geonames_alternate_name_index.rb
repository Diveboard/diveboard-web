ThinkingSphinx::Index.define :geonames_alternate_name, :with => :active_record do
  set_property :min_infix_len => 3
  set_property :sql_range_step => 300000000
  indexes name
  has geonames_core.feature_code, :as => :feature_code, :type => :string
  has geonames_core.feature_class, :as => :feature_class, :type => :string
  has geonames_core.population, :as => :population, :type => :integer
  has geonames_core.area.id, :as => :area_id, :type => :integer
  where "geonames_cores.feature_code = 'PCLI' OR (geonames_cores.feature_class = 'P' AND geonames_cores.population > 5000) and language != 'link'"
end
