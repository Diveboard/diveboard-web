class ActivityFeed

  INCLUDE_RULES = [
    { :user_id_attr => 'dives.user_id', :from => 'activities JOIN dives ON activities.dive_id = dives.id'},
    { :user_id_attr => 'dives.user_id', :from => "activities JOIN picture_album_pictures as alb ON alb.picture_id = activities.picture_id JOIN dives ON alb.picture_album_id = dives.album_id" },
    { :user_id_attr => 'activity_followings.follower_id', :from => 'activities JOIN activity_followings ON
      activity_followings.exclude = false AND
      (activity_followings.tag IS NULL            OR activity_followings.tag = activities.tag) AND
      (activity_followings.user_id IS NULL        OR activity_followings.user_id = activities.user_id) AND
      (activity_followings.dive_id IS NULL        OR activity_followings.dive_id = activities.dive_id) AND
      (activity_followings.spot_id IS NULL        OR activity_followings.spot_id = activities.spot_id) AND
      (activity_followings.location_id IS NULL    OR activity_followings.location_id = activities.location_id) AND
      (activity_followings.region_id IS NULL      OR activity_followings.region_id = activities.region_id) AND
      (activity_followings.country_id IS NULL     OR activity_followings.country_id = activities.country_id) AND
      (activity_followings.shop_id IS NULL        OR activity_followings.shop_id = activities.shop_id) AND
      (activity_followings.picture_id IS NULL     OR activity_followings.picture_id = activities.picture_id)
      LEFT JOIN dives on dives.id = activities.dive_id', :where => 'dives.privacy is null or dives.privacy = 0'
    }
  ]

  EXCLUDE_RULES = [
    { :user_id_attr => 'activity_followings.follower_id', :from => 'activities JOIN activity_followings ON
      activity_followings.exclude = true AND
      (activity_followings.tag IS NULL            OR activity_followings.tag = activities.tag) AND
      (activity_followings.user_id IS NULL        OR activity_followings.user_id = activities.user_id) AND
      (activity_followings.dive_id IS NULL        OR activity_followings.dive_id = activities.dive_id) AND
      (activity_followings.spot_id IS NULL        OR activity_followings.spot_id = activities.spot_id) AND
      (activity_followings.location_id IS NULL    OR activity_followings.location_id = activities.location_id) AND
      (activity_followings.region_id IS NULL      OR activity_followings.region_id = activities.region_id) AND
      (activity_followings.country_id IS NULL     OR activity_followings.country_id = activities.country_id) AND
      (activity_followings.shop_id IS NULL        OR activity_followings.shop_id = activities.shop_id) AND
      (activity_followings.picture_id IS NULL     OR activity_followings.picture_id = activities.picture_id)'
    }
  ]

  attr_reader :user_id
  attr_accessor :batch_size
  attr_accessor :target_threshold
  attr_accessor :target_size

  def self.for_user(user_id)
    feed = ActivityFeed.new(user_id)
  end

  def self.for_default_user
    feed = ActivityFeed.new(nil)
  end

  def self.list_for_activity(activity_id)
    feeds = []
    INCLUDE_RULES.each do |rule|
      rule[:where] = 'true' if rule[:where].nil?
      ActiveRecord::Base.connection.select_values("SELECT #{rule[:user_id_attr]} FROM #{rule[:from]} WHERE (#{rule[:where]}) AND activities.id = #{activity_id}").each do |user_id|
        feeds.push user_id
      end
    end

    excluded = []
    EXCLUDE_RULES.each do |rule|
      rule[:where] = 'true' if rule[:where].nil?
      ActiveRecord::Base.connection.select_values("SELECT #{rule[:user_id_attr]} FROM #{rule[:from]} WHERE (#{rule[:where]}) AND activities.id = #{activity_id}").each do |user_id|
        excluded.push  user_id
      end
    end
    feeds -= excluded.uniq
    return feeds.uniq.map {|id| ActivityFeed.new(id)}
  end

  def self.clear_old_objects
    # Deleting activities concerning a dive which does not exists
    ActiveRecord::Base.connection.select_values("DELETE activities.* FROM activities LEFT JOIN dives ON dives.id = activities.dive_id WHERE activities.tag = 'add_dive' AND dives.id IS NULL")
    # Deleting activities concerning a picture which does not exists or which is not linked to a dive
    ActiveRecord::Base.connection.select_values("DELETE activities.* FROM activities left join pictures ON activities.picture_id = pictures.id left join picture_album_pictures on pictures.id = picture_album_pictures.picture_id LEFT JOIN dives ON dives.album_id = picture_album_pictures.picture_album_id WHERE activities.tag = 'add_picture' AND (pictures.id IS NULL OR dives.id IS NULL)")
  end

  def user
    return User.find(@user_id) if @user_id
    return nil
  end

  def each(&block)
    items.each &block
  end

  def to_s
    "#<#{self.class}(#{@user_id})>"
  end

  def to_ary
    items
  end

private
  def initialize(user_id)
    @user_id = user_id
    @items = nil
    self.target_size = 35
    self.target_threshold = 45
    self.batch_size = 300
  end

  def items
    if @items.nil? then
      if !self.user.nil? then
        activity_list = fill_in
      else
        activity_list = fill_in_default
      end
      iteration = 0
      item_list = []
      filtered_list = []
      while iteration < (activity_list.length.to_f / batch_size).ceil && item_list.length < target_threshold  do
        iteration += 1
        filtered_list += filter activity_list.slice (batch_size*(iteration-1))..(batch_size*iteration)
        item_list = group_items filtered_list
        Rails.logger.debug "Iteration #{iteration}: Merged #{[batch_size*iteration, activity_list.length].min} activities within #{item_list.length} news"
      end
      Rails.logger.debug "Merged #{[batch_size*iteration, activity_list.length].min} activities within #{item_list.length} news in #{iteration} iterations"
      @items = item_list.slice 0..target_size
    end
    @items
  end

  def fill_in
    items = []
    INCLUDE_RULES.each do |rule|
      rule[:where] = 'true' if rule[:where].nil?
      items += Media::select_all_sanitized("SELECT activities.* FROM #{rule[:from]} WHERE (#{rule[:where]}) AND #{rule[:user_id_attr]} = #{@user_id} ORDER BY activities.created_at DESC", {})
    end
    items.uniq!
    excluded = {}
    EXCLUDE_RULES.each do |rule|
      rule[:where] = 'true' if rule[:where].nil?
      excluded_list = Media::select_values_sanitized("SELECT activities.id FROM #{rule[:from]} WHERE (#{rule[:where]}) AND #{rule[:user_id_attr]} = #{@user_id}", {})
      excluded_list.each do |id| excluded[id] = true end
    end
    items.reject! do |item| excluded[item['id']] end
    return items
  end

  def fill_in_default
    return Media::select_all_sanitized("SELECT activities.id, activities.tag, activities.created_at FROM activities JOIN dives ON activities.dive_id = dives.id
      WHERE dives.privacy is null or dives.privacy = 0
      ORDER BY activities.created_at DESC", {})
  end


  def filter(item_list)
    new_items = []
    profile_to_keep = nil
    item_list.each do |activity|
      if activity['tag'] == 'update_dive' or activity['tag'] == 'delete_dive' then
        next
      elsif activity['tag'] == 'profile_update' then
        profile_to_keep = activity if activity['created_at'] > profile_to_keep['created_at']
        next
      elsif activity['tag'] == 'add_dive' || activity['tag'] == 'add_picture' then
        new_items.push activity
      else
        nil
      end
    end

    new_items.push profile_to_keep unless profile_to_keep.nil?

    #filtering items for which the linked elements do not exist anymore
    vals = {:dive_id=>[], :user_id=>[], :picture_id=>[], :spot_id=>[]}
    new_items.map do |item|
      vals[:dive_id].push item['dive_id'] unless item['dive_id'].nil?
      vals[:user_id].push item['user_id'] unless item['user_id'].nil?
      vals[:spot_id].push item['spot_id'] unless item['spot_id'].nil?
      vals[:picture_id].push item['picture_id'] unless item['picture_id'].nil?
    end
    vals[:dive_id].uniq!
    vals[:user_id].uniq!
    vals[:spot_id].uniq!
    vals[:picture_id].uniq!
    found_dive_list = Media.select_values_sanitized('select id from dives where id in (:dive_id)', vals ) unless vals[:dive_id].blank?
    found_user_list = Media.select_values_sanitized('select id from users where id in (:user_id)', vals ) unless vals[:user_id].blank?
    found_spot_list = Media.select_values_sanitized('select id from spots where id in (:spot_id)', vals ) unless vals[:spot_id].blank?
    found_picture_list = Media.select_values_sanitized('select id from pictures where id in (:picture_id)', vals ) unless vals[:picture_id].blank?
    found_dive_ids = {nil => true}
    found_user_ids = {nil => true}
    found_spot_ids = {nil => true}
    found_picture_ids = {nil => true}
    found_dive_list.each do |id| found_dive_ids[id]=true end rescue nil
    found_user_list.each do |id| found_user_ids[id]=true end rescue nil
    found_spot_list.each do |id| found_spot_ids[id]=true end rescue nil
    found_picture_list.each do |id| found_picture_ids[id]=true end rescue nil

    filtered_items = []
    new_items.each do |a|
      next unless found_dive_ids[a['dive_id']]
      next unless found_spot_ids[a['spot_id']]
      next unless found_user_ids[a['user_id']]
      next unless found_picture_ids[a['picture_id']]
      filtered_items.push a
    end


    #loading activerecords with the includes
    return Activity.where(:id => (filtered_items.map do |item| item['id'] end)).includes([:dive, :user, :picture, :spot]).to_ary
  end

  def group_items(item_list)
    new_items = []
    item_list.group_by(&:user_id).each do |who, list_activities|
      activities_by_tag = list_activities.group_by(&:tag)
      activities_by_tag.each do |tag, list_activities_2|


        ## Split activities if they have been done than 10 days apart
        date_grouped = []
        last_date = nil
        group = []
        list_activities_2.sort {|a1,a2| a2.created_at <=> a1.created_at} .each do |activity|
          if !last_date.nil? && last_date - activity.created_at > 10.days then
            date_grouped.push group
            group = []
          end
          group.push activity
          last_date = activity.created_at
        end
        date_grouped.push group if group.count > 0

        date_grouped.each do |list_activities_3|

          if tag == 'add_picture' then
            filtered_items = []
            list_activities_3.each do |activity|
              exclude = false
              !activities_by_tag['add_dive'].nil? && activities_by_tag['add_dive'].each do |dive_activity|
                if dive_activity.dive_id == activity.dive_id then
                  exclude = true
                  break
                end
              end
              next if exclude
              filtered_items.push activity
            end
            new_items.push filtered_items unless filtered_items.empty?
            next
          end

          #default should not be to publish, but since it's currently in dev....
          new_items.push list_activities_3
        end
      end
    end
    new_items.each do |set| set.sort! do |a1,a2| a2.created_at <=> a1.created_at end end
    return new_items.sort {|set1,set2| set2.first.created_at <=> set1.first.created_at}
  end

end
