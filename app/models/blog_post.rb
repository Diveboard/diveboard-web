require 'delayed_job'

class BlogPost < ActiveRecord::Base
  extend FormatApi


  #### A blog post has many wikis
  #### published_at > date when a user published a post - if set it should show up immediately in the user's blog - wiki should be auto accepted as soon as a blog is validated
  #### published => boolean , if true, the post will show up on main blog
  #### flag_moderate_private_to_public => nil by default , true, it must be checked, false, it has been checked
  #### only the post owner and an admin can edit it

  belongs_to :blog_category
  belongs_to :user
  before_save :update_blob
  has_many :wikis, :as => :source, :order => "updated_at DESC"
  has_one :latest_wiki, :class_name => "Wiki", :conditions => "source_type = 'BlogPost'", :foreign_key => :source_id, :order => "wikis.updated_at DESC"##used for sphinx to only index the latest revision
  has_one :fb_comment, :class_name => "FbComments", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id, :order => "fb_comments.updated_at DESC"
  has_many :fb_likes, :class_name => "FbLike", :conditions => "source_type = '#{self.name}'", :foreign_key => :source_id


  def is_private_for?(options={})
    return false if options[:caller].nil?
    return true if options[:action] == :create
    return true if options[:caller].admin_rights > 2
    return true if options[:caller].id == self.user_id
    return false
  end


  def wiki user_id=nil
     Wiki.get_wiki self.class.to_s, self.id, user_id
  end


  #Replaced by polymorphic associations
  #def wikis
  #   Wiki.where(:source_type => self.class.to_s, :source_id => self.id).order("updated_at DESC")
  #end

  def wiki_html user_id=nil
    begin
      self.wiki(user_id).html
    rescue
      nil
    end
  end

  def title user_id=nil
    begin
      wiki(user_id).title
    rescue
      nil
    end
  end

  def update_wiki(opts)
    #{:text => text, :title => title}
    raise DBArgumentError.new "BlogPost id is nil, please save before adding wiki content" if self.id.nil?
    raise DBArgumentError.new "user_id is nil, please provide a proper user_id before adding wiki content" if self.user_id.nil?
    raise DBArgumentError.new "text can't be blank" if opts[:text].blank?
    raise DBArgumentError.new "title can't be blank" if opts[:title].blank?

    w = Wiki.create_wiki(self.class.to_s, self.id, opts[:text], self.user_id)
    w.title = opts[:title]
    w.save
    w.extract_pics_from_text ##always launch that in background ;)
    self.update_blob
    return w
  end

  def published_month
    if published_at.month < 10
      "0"+published_at.month.to_s
    else
      published_at.month.to_s
    end
  end

  def permalink
    if published
      "/community/#{self.blog_category.blob}/#{self.published_at.year}/#{published_month}/#{self.blob}-#{self.shaken_id}"
    elsif !published_at.nil?
      "/#{self.user.vanity_url}/posts/#{self.blob}-#{self.shaken_id}"
    else
      "/community/edit/"+self.shaken_id
    end
  end

  def fullpermalink *options
    HtmlHelper.find_root_for(options).chop + permalink
  end

  def fullcommentslink
    "#{ROOT_URL}lnk/#{self.shaken_id}"
  end


  def shaken_id
    "B#{Mp.shake(self.id)}"
  end

  def self.fromshake code
    self.find(idfromshake code)
  end

  def self.idfromshake code
    if code[0] == "B"
       i =  Mp.deshake(code[1..-1])
    else
       i = code.to_i
    end
    if i.nil?
      raise DBArgumentError.new "Invalid ID"
    else
      return i
    end
  end

  def fulltinypermalink
    ROOT_TINY_URL + shaken_id
  end

  def previous
    ##previous blog post
    begin
      BlogPost.where(:published => true).where("published_at < '#{self.published_at}'").order("published_at DESC").limit(1).first
    rescue
      nil
    end
  end

  def next
    ##previous blog post
    begin
      BlogPost.where(:published => true).where("published_at >'#{self.published_at}'").order("published_at ASC").limit(1).first
    rescue
      nil
    end
  end

  def author_previous
    ##previous blog post
    begin
      BlogPost.where("published_at is not NULL").where(:user_id => self.user_id).where("published_at < '#{self.published_at}'").order("published_at DESC").limit(1).first
    rescue
      nil
    end
  end

  def author_next
    ##previous blog post
    begin
      BlogPost.where("published_at is not NULL").where(:user_id => self.user_id).where("published_at >'#{self.published_at}'").order("published_at ASC").limit(1).first
    rescue
      nil
    end
  end

  def status
    if !published_at.nil?
      :published
    elsif published
      :selected
    elsif published_at.nil?
      :draft
    end
  end

  def update_blob
    begin
      self.blob = self.wiki.title.to_url
    rescue
    end
  end

  def blob
    read_attribute(:blob) || begin self.wiki.title.to_url rescue "unverified-post" end
  end

  def has_comments?
    ##TODO : wire to real comments things
    return false
  end

  def publish_to_fb_page
    #Since it's workign asynchronously, we'll let it fail vocally ;)

    pageowner = User.find(30) ## alex owns the diveboard FB page (so 30 being hardcoded makes somehow sense)
    graph = Koala::Facebook::API.new(pageowner.fbtoken)
    accounts = graph.get_connections('me', 'accounts')
    accounts.reject!{|e| e["id"]!="140880105947100"} ## getting the data about the Diveboard page
    page_token = accounts[0]["access_token"] ## getting a token to act as page
    page_access = Koala::Facebook::API.new(page_token)
    if self.blog_category_id != BlogCategory.find_by_name("Question").id
      message = "New post on Diveboard : #{title}"
    else
      message = "New question from a Diveboarder : #{title}"
    end
    result = page_access.put_object(
      140880105947100,
      "feed",
      :message =>message,
      :name => title,
      :caption => "by #{user.nickname}",
      :description => abstract,
      :link => self.fullpermalink(:canonical),
      :picture => begin wiki.pictures.first.thumb rescue "#{ROOT_URL}img/logo_50.png" end
      )
    self.fb_graph_id = result
    self.save!
    return result
  end
  handle_asynchronously :publish_to_fb_page

  def thumbnail?
    @internal_thumbnail ||= self.wiki.pictures.first.thumbnail rescue nil
    return !@internal_thumbnail.nil?
  end

  def thumbnail
    @internal_thumbnail ||= self.wiki.pictures.first.thumbnail rescue nil
    return @internal_thumbnail || (ROOT_URL+"img/logo_50.png")
  end

  def abstract options={}
    user_id = options[:viewer_id]
    len = options[:length]?options[:length].to_i : 250

    txt = (begin Nokogiri::HTML(wiki_html(user_id)).text rescue "" end)
    txt.gsub! /^[[:space:]]*/, ''
    txt.gsub! /^[[:space:]]*$[[:space:]]*/, ''
    txt.gsub! /^ +/, ' '

    return txt if txt.length <= len

    #try to cut at new paragraph if close enough
    subtxt = txt[0..(len-4)]
    trunc_word = subtxt.match(/[^\n]+\z/)[0] rescue nil
    if trunc_word && trunc_word.length <= [len/5, 3].max then
      return subtxt[0..(-2-trunc_word.length)] + " ..."
    end

    #try to cut at word if close enough
    subtxt = txt[0..(len-3)]
    trunc_word = subtxt.match(/\s+[^ ]*\z/)[0] rescue nil
    if trunc_word && trunc_word.length <= [len/10, 3].max then
      return subtxt[0..(-1-trunc_word.length)] + "..."
    else
      return subtxt[0..-2] + "..."
    end
  end

  def abstract_html options={}
    txt = abstract options
    (CGI::escapeHTML txt).split("\n").map do |p| "<p>#{p}</p>" end .join.html_safe
  end

  def update_disqus_comments msg
    ## will grab the disqus comment of the dive and save it
    DisqusComments.update_comment self, msg
  end
  handle_asynchronously :update_disqus_comments

  def update_fb_comments
    ## will grab the FB comment of the dive and save it
    ## dive comment link : http://www.diveboard.com/ksso/D25AZIW
    require 'curb'
    fburl = "http://graph.facebook.com/v2.0/comments?id=#{fullcommentslink}"
    res = Curl.get(fburl)
    if res.response_code == 200
      FbComments.update_fb_comments self, res.body_str
    end
  end
  handle_asynchronously :update_fb_comments

  def update_fb_like
    FbLike.get self, self.fulltinypermalink, fullcommentslink
  end
  handle_asynchronously :update_fb_like



end
