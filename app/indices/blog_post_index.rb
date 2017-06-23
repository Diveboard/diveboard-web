ThinkingSphinx::Index.define :blog_post, :with => :active_record, :delta => ThinkingSphinx::Deltas::DelayedDelta do
  set_property :min_infix_len => 3
  #indexes latest_wiki.data, :as => :post_data
  #indexes latest_wiki.title , :as => :post_title
  indexes [wikis.data, wikis.title], :as => :posts ## indexes all wikis per post
  indexes blob
  has published, :type => :boolean
  has id
end
