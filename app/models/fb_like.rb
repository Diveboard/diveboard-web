require 'curb'

class FbLike < ActiveRecord::Base
  belongs_to :source, :polymorphic => true

  def self.get object, *urls
    urls = [object.fullpermalink(:canonical)] if urls.count == 0
    urls_string = urls.map do |u| "'#{u}'" end .join ','

    fburl = "http://graph.facebook.com/v2.0/fql?q=select click_count,comment_count,comments_fbid,like_count,share_count,total_count,commentsbox_count,click_count from link_stat where url IN (#{urls_string})"
    res = Curl.get(URI.encode fburl)
    Rails.logger.debug "Requesting: #{fburl}"
    Rails.logger.debug res.body_str
    if res.response_code == 200
      FbLike.transaction do
        data = JSON.parse(res.body_str)
        urls.each_with_index do |url, idx|
          FbLike.where(:url => url).map &:delete
          FbLike.create do |lk|
            lk.source = object
            lk.url = url
            lk.click_count = data['data'][idx]['click_count']
            lk.comment_count = data['data'][idx]['comment_count']
            lk.comments_fbid = data['data'][idx]['comments_fbid']
            lk.commentsbox_count = data['data'][idx]['commentsbox_count']
            lk.like_count = data['data'][idx]['like_count']
            lk.share_count = data['data'][idx]['share_count']
            lk.total_count = data['data'][idx]['total_count']
          end
        end
      end
    end

  end



  def self.get_in_batch objects
    urls = {}
    objects.each do |o|
      l = o.fullpermalink(:canonical)
      next unless l.match /^http:\/\//
      urls[l] ||= []
      urls[l].push o
    end

    return if urls.keys.count == 0
    urls_string = urls.keys.map do |u| "'#{u}'" end .join ','

    fburl = "http://graph.facebook.com/v2.0/fql?q=select normalized_url,click_count,comment_count,comments_fbid,like_count,share_count,total_count,commentsbox_count,click_count from link_stat where url IN (#{urls_string})"
    res = Curl.get(URI.encode fburl)
    Rails.logger.debug "Requesting: #{fburl}"
    Rails.logger.debug res.body_str

    if res.response_code == 200
      data = JSON.parse(res.body_str)
      FbLike.transaction do
        data['data'].each do |stats|
          targets = urls[stats['normalized_url']]
          targets ||= urls[stats['normalized_url'].gsub('//www.', '//')]
          if targets.nil? || targets.count == 0 then
            puts "normalized_url not found: #{stats['normalized_url']}"
            next
          end
          targets.each do |target|
            url = target.fullpermalink(:canonical)
            FbLike.where(:source_type => target.class.name, :source_id => target.id).map &:delete
            FbLike.create do |lk|
              lk.source = target
              lk.url = url
              lk.click_count = stats['click_count']
              lk.comment_count = stats['comment_count']
              lk.comments_fbid = stats['comments_fbid']
              lk.commentsbox_count = stats['commentsbox_count']
              lk.like_count = stats['like_count']
              lk.share_count = stats['share_count']
              lk.total_count = stats['total_count']
            end
          end
        end
      end
    end
  end



end
