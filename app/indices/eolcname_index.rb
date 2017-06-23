ThinkingSphinx::Index.define :eolcname, :with => :active_record do
  set_property :min_infix_len => 3
  indexes cname
  indexes eolsname.category, :as => :category
  indexes eolsname.taxonrank, :as => :taxonrank

  #attributes
  has eolsname_id, language
end
