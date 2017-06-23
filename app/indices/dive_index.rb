ThinkingSphinx::Index.define :dive, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 4
  indexes :notes
  has privacy
  has id
end
