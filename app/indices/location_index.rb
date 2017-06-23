ThinkingSphinx::Index.define :location, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 2
  indexes name
  has id
end
