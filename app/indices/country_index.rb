ThinkingSphinx::Index.define :country, :with => :active_record do
  set_property :min_infix_len => 2
  indexes cname
  indexes cname, :as => :name
  has id
end
