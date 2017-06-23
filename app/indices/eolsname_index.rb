ThinkingSphinx::Index.define :eolsname, :with => :active_record do
  set_property :min_infix_len => 3
  indexes sname
  indexes [eolcnames.cname], :as => :cname
  indexes category
  indexes taxonrank
end
