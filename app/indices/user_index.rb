ThinkingSphinx::Index.define :user, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 3
  indexes nickname
  indexes vanity_url
  indexes first_name
  indexes last_name
  has 'shop_proxy_id is not null', :as => :is_group, :type => :boolean
end
