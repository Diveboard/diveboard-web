class DedupUserBuddies < ActiveRecord::Migration
  def self.up

    execute "UPDATE external_users set nickname = NULL where nickname regexp '^[[:blank:]]*$'"
    execute "UPDATE external_users set fb_id = NULL where fb_id regexp '^[[:blank:]]*$'"
    execute "UPDATE external_users set email = NULL where email regexp '^[[:blank:]]*$'"
    execute "UPDATE external_users set picturl = NULL where picturl regexp '^[[:blank:]]*$'"


    to_be_continued = true
    while to_be_continued do
      results = execute "select min(e.id) new_id, group_concat(distinct e.id) old_ids from external_users e, users_buddies b where e.id = b.buddy_id and b.buddy_type = 'ExternalUser' group by fb_id, nickname, email, b.user_id having count(distinct e.id) > 1"
      to_be_continued = false
      results.each do |row|
        new_id = row[0]
        old_ids = row[1]
        execute "UPDATE users_buddies set buddy_id = #{new_id} where buddy_id in (#{old_ids}) and buddy_type = 'ExternalUser'"
        execute "UPDATE dives_buddies set buddy_id = #{new_id} where buddy_id in (#{old_ids}) and buddy_type = 'ExternalUser'"
        to_be_continued = true
      end
    end

  end

  def self.down
  end
end
