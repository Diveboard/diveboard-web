@cont = 0
File.open("parsedCommentsWXR.xml", 'w') do |file|
	doc_head = '<?xml version="1.0" encoding="UTF-8"?>
	<rss version="2.0"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:dsq="http://www.disqus.com/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:wp="http://wordpress.org/export/1.0/"
	>
	 <channel>'
	file.write "#{doc_head}"
	FbComments.where("raw_data <> '{\"data\":[]}'").includes(:source).find_in_batches(batch_size: 100) do |group|
		@cont = @cont + 1
		puts "new batch #{@cont}" 
		group.each { |comment|
			msgs = JSON.parse(comment.raw_data)
			if !msgs["data"].empty? then
				next if comment.source.nil?
				if comment.source_type == 'Picture' then
					if !Picture.find(comment.source_id).dive.nil? then
						disqus_identifier = "Dive/#{Picture.find(comment.source_id).dive.shaken_id}"
					else
						next
					end 	
				else
					disqus_identifier = "#{comment.source_type}/#{comment.source.shaken_id}"
				end
				head = "
					<item>
						<title></title>
						<link>#{comment.source.fullpermalink(:canonical)}</link>
						<content:encoded><![CDATA[Diveboard Disqus-enabled Comment]]></content:encoded>
						<dsq:thread_identifier>#{disqus_identifier}</dsq:thread_identifier>
						<wp:post_date_gmt>#{Time.parse(msgs["data"][0]["created_time"]).strftime("%Y-%d-%m %H:%M:%S")}</wp:post_date_gmt>
						<wp:comment_status>open</wp:comment_status>"
      			file.write "#{head}\n"
      			msgs["data"].each do |x|
      				user = User.where("fb_id = #{x["from"]["id"]}")
      				if user.empty? then
      					diveboard_id = "#{x["from"]["id"]}"
      					avatar = "http://graph.facebook.com/v2.0/#{x["from"]["id"]}/picture?width=200&height=200"
      					author_url = ""
      					author_email = ""
      				else
      					diveboard_id = user[0].id
      					avatar = user[0].picture
      					author_url = user[0].fullpermalink(:canonical)
      					author_email = user[0]["email"]
      				end
      				body = "
	      				<wp:comment>
	      				<wp:comment_id>#{x["id"]}</wp:comment_id>
	      				<wp:comment_author>#{x["from"]["name"]}</wp:comment_author>
	      				<wp:comment_author_email>#{author_email}</wp:comment_author_email>
	      				<wp:comment_author_url>#{author_url}</wp:comment_author_url>
	      				<wp:comment_author_IP>0.0.0.0</wp:comment_author_IP>
	      				<wp:comment_date_gmt>#{Time.parse(x["created_time"]).strftime("%Y-%d-%m %H:%M:%S")}</wp:comment_date_gmt>
	      				<wp:comment_content><![CDATA[#{x["message"]}]]></wp:comment_content>
	      				<wp:comment_approved>1</wp:comment_approved>
	      				<wp:comment_parent>0</wp:comment_parent>
	      				</wp:comment>
	      				"
      				file.write "#{body}"       				
      			end
				file.write "
					</item>\n" 
			end
		}
	end
	file.write "
	</channel>\n</rss>"
end
