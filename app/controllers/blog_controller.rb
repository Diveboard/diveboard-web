class BlogController < ApplicationController
  before_filter :init_logged_user, :prevent_browser_cache, :save_origin_url, :signup_popup_hidden  #init the graph connection and everyhting user related

  def feed
    if !params[:vanity_url].nil?
      @author = User.find_by_vanity_url(params[:vanity_url])
    else
      @author = nil
    end
    @posts = BlogPost.where(:published => true).order("published_at DESC")
    if !@author.blank?
      @posts = @posts.where(:user_id => @author.id)
      @dives = Dive.where(:user_id => @author.id).where(:privacy => 0).includes([:user, :dives_buddies, :db_buddies, :ext_buddies,  :eolcnames, :eolsnames, {:spot => [:country, :location], :eolcnames => :eolsname}]).order("created_at DESC")
    else
      @dives = []
    end
    @posts = @posts.limit(20)
    self.formats = [:rss]
    render 'blog/feed.rss.builder', :layout => false
    return
  end

  def newsletter
    @content = :newsletter
    @pagename = "COMMUNITY"
    @ga_page_category = "newsletter"
    begin
      user = User.fromshake(params[:user_id])
    rescue
      user = @user
    end
    @recipient = @user
    begin
      if !params[:id].blank?
        letter = Newsletter.find(params[:id].to_i)
      else
        list = Newsletter.where("distributed_at IS NOT NULL").order("distributed_at DESC")
        if list.blank?
          list = Newsletter.where("created_at IS NOT NULL").order("created_at DESC")
        end
        letter = list.first
      end
    rescue
      render 'layouts/404', :layout => false
      return
    end

    html = HtmlHelper::Inliner.new((render_to_string :partial => 'notify_user/newsletter', :locals => {:user => user, :letter => letter, :date =>(letter.distributed_at || letter.created_at)}) , true, {}, ['public/styles/newsletter.css']).execute.html_safe
    @title = letter.subject
    render :inline => html,:layout => 'main_layout'
    return

  end

  def newsletter_unsuscribe

    ##no need for show login popup here

    @ga_page_category = "newsletter_unsubscribe"
    if params[:do_action] == "unsuscribe"
      begin
        ValidationHelper.check_email_format params[:contact_email]

        if params[:scope].nil? || params[:scope] == ""
          scope = "undefined"
        else
          scope = params[:scope]
        end
        if !params[:recipient_id].nil? && params[:recipient_id]!=""
          target = hash_to_object(params[:recipient_id])
          raise DBArgumentError.new "bad recipient_email" if target.contact_email != params[:contact_email]
          EmailSubscription.change_subscription(hash_to_object(params[:recipient_id]), scope, false)
        else
          EmailSubscription.change_subscription(params[:contact_email], scope, false)
        end
        @message = "Your email has been successfully opted-out"

      rescue
        flash[:notice] = "Could not unsuscribe"
        logger.debug $!.message
      end
    else
      begin
        if !params[:recipient_id].nil?

          @nl_email = hash_to_object(params[:recipient_id]).contact_email
          if @nl_email != params[:recipient_email]
            ## check that can't be forged too easily
            @nl_email = nil
            params[:recipient_id] = nil
            params[:recipent_email] = nil
          end
        elsif !params[:email].nil?
          @nl_email = params[:email]
        else
          @nl_email = nil
        end
      rescue
        @nl_email = nil
      end
    end
    render 'newsletter_unsuscribe', :layout => 'main_layout'
    return
  end


  def home
    #renders the blog homepage
    ##prepping sidebar
    @pagename = "COMMUNITY"
    @ga_page_category = "community"
    @max_weight = 1
    question_category = BlogCategory.find_by_name("Question").id

    @content = params["content"] # used in the meta tags generation

    if params["content"] == :post
      ## specific blog post
        logger.debug "Showing a blog post"
        begin
          raise DBArgumentError.new "The url you've entered is not properly formatted" if params["title"].blank?
          if (m=params["title"].match(/^.*\-(B[0-9a-zA-Z]+)$/))
            begin
              @post = BlogPost.fromshake(m[1])
            rescue
              @post = BlogPost.find_by_blob(params["title"])
            end
          else
            @post = BlogPost.find_by_blob(params["title"])
          end
          raise DBArgumentError.new "Could not find the post you requested" if @post.nil?

        rescue
          flash[:notice] = $!.message
          logger.debug $!.message
          redirect_to "/community" ## we redirect to the home page
          return
        end
    elsif params["content"] == :preview_post
        logger.debug "Showing the preview of a post"
        begin
          @post = BlogPost.fromshake(params[:id])
          raise DBArgumentError.new "You are not owning this post" unless @user.can_edit? @post

        rescue
          flash[:notice] = $!.message
          logger.debug $!.message
          redirect_to "/community" ## we redirect to the home page
          return
        end
    elsif params["content"] == :edit
      signup_popup_force if @user.nil?
      begin
        if !params["post_id"].blank?
            Rails.logger.debug "getting post_id: "+params["post_id"]
            @post = BlogPost.fromshake(params["post_id"])
            if @user.nil? || !@user.can_edit?(@post)
              @post = nil
              raise DBArgumentError.new "You are not the owner of this article"
            end
        end
        if !params["wiki_id"].blank?
          @wiki = Wiki.fromshake(params["wiki_id"])
          if @post.nil?
            @wiki = nil
          elsif @wiki.source_id != @post.id && @wiki.source_type != @post.class.to_s.titleize
            @wiki = nil
            raise DBArgumentError.new "Post id and wiki id are not matching"
          elsif @wiki.verified_user_id.nil? && ((!@user.nil? && @post.user_id != @user.id) || @user.nil?)
            @wiki = nil
            raise DBArgumentError.new "Current user doesn't own this entry  or isn't logged"
          end
        end
      rescue
        flash[:notice] = $!.message
        if @post.nil?
          redirect_to "/community"
          return
        end
      end
    elsif params["content"] == :category
      begin
        logger.debug "Showing the posts with category '#{params[:category]}'"
        category = BlogCategory.find_by_blob(params[:category])
        raise DBArgumentError.new "Unknown category", category: params[:category] if category.nil?
        @post_list= BlogPost.where(:blog_category_id => category.id).order("published_at DESC, updated_at DESC").paginate(:page => params[:page], :per_page => 10)
      rescue
        flash[:notice] = $!.message
        redirect_to "/community"
        return
      end
    elsif params["content"] == :user
      begin
        logger.debug "Showing the user page"
        @author = User.find_by_vanity_url params["vanity_url"]
        raise DBArgumentError.new "No such user" if @author.nil? || !@author.shop_proxy_id.nil?
        @post_list= BlogPost.where(:user_id => @author.id)
        if @user.nil? || (!@user.nil? && @user.id != @author.id)
          params["content_type"] = :user_published
        end

        case  params["content_type"]
          when :user_published
            @post_list = @post_list.where("published_at is not null")
          when :user_draft
            @post_list = @post_list.where("published_at is null")
          when :user_pending
            @post_list = @post_list.where(:flag_moderate_private_to_public => true)
          when :user_selected
            @post_list = @post_list.where(:published => true)
          when :user_rejected
            @post_list = @post_list.where("published is false and published_at is not null")
          else
            @post_list = @post_list.where(:published => true)
        end
         @post_list = @post_list.order("published_at DESC, updated_at DESC").paginate(:page => params[:page], :per_page => 10)
         #@post_list = @post_list.reject {|p| p.nil?}

      rescue
        flash[:notice] = $!.message
        redirect_to "/community"
        return
      end

    else
      ##params :page for pagination
        logger.debug "Showing the blog homepage"
        page_num = Integer(params[:page]) rescue nil
        begin
          @post_list= BlogPost.where(:published => true)
          if !params[:year].blank? && !params[:month].blank?
            #Y & M
            date = Date.new(params[:year].to_i,params[:month].to_i)
            @post_list = @post_list.where("published_at BETWEEN '#{date}' AND '#{date.end_of_month}'")
          elsif !params[:year].blank? && params[:month].blank?
            date = Date.new(params[:year].to_i,params[:month].to_i)
            @post_list = @post_list.where("published_at BETWEEN '#{date}' AND '#{date.end_of_year}'")
            # Y only
          end
          if !params[:category].blank?
            cat  = BlogCategory.find_by_name(params[:category])
            if !cat.nil?
               @post_list = @post_list.where(:blog_category_id => cat.id)
            end
          else
            ##we filter out the questions from the homepage
            @post_list = @post_list.where("blog_category_id <> #{question_category}")
          end

          @post_list = @post_list.order("published_at DESC").paginate(:page => page_num, :per_page => 10)
        rescue
          @post_list = BlogPost.where(:published => true).order("published_at DESC").paginate(:page => page_num, :per_page => 10)
        end
    end
    if !@author.nil?
      @latest_posts = BlogPost.where(:published => true).where(:user_id => @author.id ).order("published_at DESC").limit(5)
      @questions = BlogPost.where(:published => true).where(:user_id => @author.id ).where("blog_category_id = #{question_category}").order("created_at DESC").limit(5)
      @post_history = (BlogPost.where(:published=>true).where(:user_id => @author.id ).order("published_at DESC").group_by{ |c| [c.published_at.year,c.published_at.month] })
      @categories = BlogPost.where(:user_id => @author.id ).where("blog_category_id is not null").select("blog_category_id, count(*) as post_count").group("blog_category_id").order("post_count DESC").map{|u|
        if u.post_count > @max_weight then @max_weight = u.post_count end
          {:weight => u.post_count, :text => BlogCategory.find(u.blog_category_id).name.titleize, :link => BlogCategory.find(u.blog_category_id).permalink}
      }
    else
      @latest_posts = BlogPost.where(:published => true).order("published_at DESC").limit(5)
      @questions = BlogPost.where(:published => true).where("blog_category_id = #{question_category}").order("created_at DESC").limit(5)
      @post_history = (BlogPost.where(:published=>true).order("published_at DESC").group_by{ |c| [c.published_at.year,c.published_at.month] })
      @categories = BlogPost.where("blog_category_id is not null").select("blog_category_id, count(*) as post_count").group("blog_category_id").order("post_count DESC").map{|u|
        if u.post_count > @max_weight then @max_weight = u.post_count end
          {:weight => u.post_count, :text => BlogCategory.find(u.blog_category_id).name.titleize, :link => BlogCategory.find(u.blog_category_id).permalink}
      }
    end

    render 'blog_layout', :layout => 'main_layout'
    return
  end

  def update
    ## must be called via post
    begin
      raise DBArgumentError.new "User is not logged" if @user.nil?
      if params["id"].blank?
        post = BlogPost.new
        post.user_id = @user.id
      else
        post = BlogPost.find(params["id"].to_i)
        raise DBArgumentError.new "You can't edit this post" if !@user.can_edit? post
      end

      post.blog_category = BlogCategory.find_or_create_by_name(params["category"])
      if params["comments_type"].match(/standard/i)
        post.comments_question = 0
      else
        post.comments_question = 1
      end
      if params["ask_review"] == "true"
        ##this actually publishes the article for the user
        post.flag_moderate_private_to_public = true
        post.published_at = DateTime.now
      end
      post.save
      w = post.update_wiki({:text => params["text"], :title =>params["title"]})

      if params["ask_review"] == "true" || !post.published_at.nil?
        ## user selected version of the article to be published
        w.verified_user_id = @user.id
        w.save
        w.reload
        post.flag_moderate_private_to_public = true
        post.save
        post.reload
      end

      render :json => {:success => true, :id => post.id, :redirect => post.permalink, :redirect_edit => "/community/edit/"+post.shaken_id+"/"+w.shaken_id}

    rescue
      Rails.logger.debug $!.message
      Rails.logger.debug $!.backtrace
      render :json => {:success=> false, :error => $!.message}
    end
  end

  def delete
    begin
      raise DBArgumentError.new "User is not logged" if @user.nil?
      raise DBArgumentError.new "No post id to delete" if params["id"].blank?
      post = BlogPost.fromshake(params["id"])
      raise DBArgumentError.new "Post has comments so it cannot be deleted" if post.has_comments?
      raise DBArgumentError.new "Post is on the main blog so it can't be deleted" if post.published == true
      raise DBArgumentError.new "User is not owner if this post" if !@user.can_edit? post

      post.wikis.each do |w|
        w.destroy
      end
      post.destroy
      render :json => {:success => true}
      return
    rescue
      Rails.logger.debug $!.message
      Rails.logger.debug $!.backtrace
      render :json => {:success=> false, :error => $!.message}
      return
    end

  end

end
