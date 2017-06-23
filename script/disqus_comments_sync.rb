File.open("disqus_comments.txt", 'w') do |file|
	
	# file.write "Disqus Comments retrieved from Disqus.com\n"
	@connections = Hash.new

	t = Time.now 
	def retrieve_dsq_comments file, cursor_id
		if cursor_id.nil?
			dsq_post_list_url = "http://disqus.com/api/3.0/posts/list.json?api_key=#{DISQUS_PUBLIC_KEY}&forum=#{DISQUS_PREFIX}&limit=100&related=thread"
		else
			dsq_post_list_url = "http://disqus.com/api/3.0/posts/list.json?api_key=#{DISQUS_PUBLIC_KEY}&forum=#{DISQUS_PREFIX}&limit=100&cursor=#{cursor_id}&related=thread"
		end

		res = Curl.get(dsq_post_list_url)
		if res.response_code == 200 then
	      	res_json = JSON.parse res.body_str
	       
	        if res_json["code"] == 0  then
		        
		        # It was a succesful API call
				cursor = res_json["cursor"]
			    dsq_response = res_json["response"]
			    puts dsq_response
			    dsq_response.map {|comment|
			    	puts comment
			    	if !comment["thread"]["identifiers"].nil? && !comment["thread"]["identifiers"].empty? then
				    	ident = comment["thread"]["identifiers"][0].split('/')
				    	if ident[0] == 'Dive' || ident[0] == 'dive' then
							_source = Dive.fromshake ident[1]
						elsif ident[0] == 'BlogPost' then
							_source = BlogPost.fromshake ident[1]
						else
							next
						end
					else
						next
					end

					#we make a user details API call for every unique user that wrote a comment
					if !@connections.has_key?(comment["author"]["id"]) then
						dsq_user_details_url = "https://disqus.com/api/3.0/users/details.json?api_key=#{DISQUS_PUBLIC_KEY}&user=#{comment["author"]["id"]}"
		    			res = Curl.get(dsq_user_details_url)
		    			user_connections = nil

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
					      	@connections[comment["author"]["id"]] = user_connections
					    end
		    		end

		    		begin
						DisqusComments.create{|e|
						    e.source = _source
						    e.body = comment["raw_message"]
						    e.comment_id = comment["id"]
						    e.thread_link = comment["thread"]["link"]
						    e.thread_id = comment["thread"]["id"]
						    e.forum_id = comment["thread"]["forum"]
						    e.date = comment["createdAt"]
						    e.parent_comment_id = comment["parent"]
						    e.author_name = comment["author"]["name"]
						    e.author_url = comment["author"]["url"]
						    e.connections = user_connections
						    e.diveboard_id = diveboard_user_id
						    file.write "#{e.author_name} said on #{e.date}:\n\"#{e.body}\"\n\n"
					    }
				    rescue ActiveRecord::RecordNotUnique => e
  						Rails.logger.warn(e)
  						puts "Record was not inserted due to duplicate key"
					end
			    }
			    if cursor["hasNext"] then
			    	retrieve_dsq_comments file, cursor["next"]
			    end
		  	end
		end
    end


	retrieve_dsq_comments file, nil
	puts "Time elapsed #{Time.now - t}"
end
