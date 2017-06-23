ThinkingSphinx::Index.define :area, :with => :active_record do
  set_property :min_infix_len => 3
  indexes geonames_core.name, :as => :area_name
  has active, :as => :active
  has id, :as => :area_id
  where "active = true"
end
