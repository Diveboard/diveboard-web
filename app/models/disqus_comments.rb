class DisqusComments < ActiveRecord::Base
  attr_accessible :author_email, :author_name, :author_url, :body, :comment_id, :date, :forum_id, :parent_comment_id, :thread_id, :thread_link, :connections
  belongs_to :source, polymorphic: true


  def connections
    return JSON.parse(read_attribute(:connections)) unless read_attribute(:connections).nil?
  end

  def connections=(v)
    if v.nil? then
      write_attribute(:connections, nil)
    else
      write_attribute(:connections, v.to_json)
    end
  end

  def self.update_comment object, msg
  	Rails.logger.debug "Entered in Disqus self.update_disqus_comments with #{msg.to_s}"
    target = nil
    # DisqusComments.where(:source_type => object.class.name).where(:source_id => object.id).each_with_index do |e,i|
      
    # end
    dsq_post_details_url = "https://disqus.com/api/3.0/posts/details.json?api_key=#{DISQUS_PUBLIC_KEY}&post=#{msg[:id]}"
    res = Curl.get(dsq_post_details_url)
    # logger.debug "Disqus response for comment #{msg[:id]}"
    # logger.debug "!!!!!!!!#{res.body_str}"
    if res.response_code == 200
      res_json = JSON.parse res.body_str
      thread_id = res_json["response"]["thread"]
      forum_id = res_json["response"]["forum"]
      parent_comment_id = res_json["response"]["parent"]
      date = res_json["response"]["createdAt"]
      dsq_user_id = res_json["response"]["author"]["id"]
    end

    dsq_user_details_url = "https://disqus.com/api/3.0/users/details.json?api_key=#{DISQUS_PUBLIC_KEY}&user=#{dsq_user_id}"
    res = Curl.get(dsq_user_details_url)
    user_connections = nil
    # logger.debug "Disqus response for user #{msg[:id]}"
    # logger.debug "!!!!!!!!#{res.body_str}"
    if res.response_code == 200
      res_json = JSON.parse res.body_str
      user_name = res_json["response"]["name"]
      user_url = res_json["response"]["url"]
      user_connections = res_json["response"]["connections"]
     #Checking if it is a diveboard user 
      if !res_json["response"]["remote"].nil? && !res_json["response"]["remote"].empty? && res_json["response"]["remote"]["domain"] == "diveboard" then 
        diveboard_user_id = res_json["response"]["remote"]["identifier"]
      else
        diveboard_user_id = nil
      end
    end

    dsq_thread_details_url = "https://disqus.com/api/3.0/threads/details.json?api_key=#{DISQUS_PUBLIC_KEY}&thread=#{thread_id}"
    res = Curl.get(dsq_thread_details_url)
    if res.response_code == 200
      res_json = JSON.parse res.body_str
      thread_link = res_json["response"]["link"]
    end

    if !object.nil?
      comment = DisqusComments.create{|e|
        e.source = object
        e.body = msg[:text]
        e.comment_id = msg[:id]
        e.thread_link = thread_link
        e.thread_id = thread_id
        e.forum_id = forum_id
        e.date = date
        e.parent_comment_id = parent_comment_id
        e.author_name = user_name
        e.author_url = user_url
        e.connections = user_connections
        e.diveboard_id = diveboard_user_id
      }
      logger.debug "Just created a new DisqusComments #{comment.id}"
    end
  end
end
