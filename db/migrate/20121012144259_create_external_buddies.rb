class CreateExternalBuddies < ActiveRecord::Migration
  def self.up
    create_table :external_users do |t|
      t.integer :fb_id
      t.text :nickname
      t.string :email
      t.text :picturl
      t.timestamps
    end
    change_column :external_users, :fb_id, :bigint
    add_index :external_users, :email
    add_index :external_users, :fb_id

    create_table :dives_buddies do |t|
      t.integer :dive_id, :null => false
      t.string :buddy_type, :null => false
      t.integer :buddy_id, :null => false
    end

    add_index :dives_buddies, :dive_id
    add_index :dives_buddies, [:buddy_id, :buddy_type]

    create_table :users_buddies do |t|
      t.integer :user_id, :null => false
      t.string :buddy_type, :null => false
      t.integer :buddy_id, :null => false
      t.datetime :invited_at
    end

    add_index :users_buddies, :user_id
    add_index :users_buddies, [:buddy_id, :buddy_type]



    begin
      ExternalUser.transaction do 
        ActiveRecord::Migration.select_all("select id, user_id, buddies from dives where buddies != '[]'").each do |row|
          dive_id = row['id']
          user_id = row['user_id']
          buddies = JSON.parse(row['buddies'])
          buddies.each do |buddy|
            buddy.except! 'fb_id' if buddy['fb_id'].blank? || buddy['fb_id'] == 0
            buddy.except! 'email' if buddy['email'].blank?
            buddy.except! 'picturl' if buddy['picturl'].blank?

            if !buddy['db_id'].blank? && buddy['db_id'].to_i > 0 then
              Media::insert_bulk_sanitized 'dives_buddies', [{:dive_id => dive_id, :buddy_type => 'User', :buddy_id => buddy['db_id'].to_i}]
              Media::insert_bulk_sanitized 'users_buddies', [{:user_id => user_id, :buddy_type => 'User', :buddy_id => buddy['db_id'].to_i}]
            else
              u = ExternalUser.find_or_create buddy
              Media::insert_bulk_sanitized 'dives_buddies', [{:dive_id => dive_id, :buddy_type => u.class.name, :buddy_id => u.id}]
              Media::insert_bulk_sanitized 'users_buddies', [{:user_id => user_id, :buddy_type => u.class.name, :buddy_id => u.id}]
            end
          end
        end
      end
    rescue
      puts $!.message
      puts $!.backtrace.join "\n"
      self.down
      raise $!
    end

    #removing doubles on ExternalUser
    begin
      ExternalUser.transaction do 
        ActiveRecord::Migration.select_all("SELECT min(external_users.id) new_id, 
            GROUP_CONCAT(external_users.id) old_ids, 
            max(users_buddies.invited_at) new_invited_at 
          FROM users_buddies, external_users 
          WHERE users_buddies.buddy_id = external_users.id 
            and users_buddies.buddy_type = 'ExternalUser' 
            and fb_id is null 
          group by users_buddies.user_id, CONCAT(nickname, IFNULL(email, 'NULL')) 
          having count(*) > 1").each do |row|

          ActiveRecord::Migration.execute "UPDATE dives_buddies set buddy_id=#{row['new_id']} where buddy_type='ExternalUser' and buddy_id in (#{row['old_ids']})"
          ActiveRecord::Migration.execute "DELETE FROM users_buddies where buddy_type='ExternalUser' and buddy_id in (#{row['old_ids']}) and buddy_id != #{row['new_id']}"
          ActiveRecord::Migration.execute "DELETE FROM external_users where id in (#{row['old_ids']}) and id != #{row['new_id']}"
        end
      end
    rescue
      puts $!.message
      puts $!.backtrace.join "\n"
      self.down
      raise $!
    end

    #Removing doubles on users_buddies
    begin
      ExternalUser.transaction do 
        ActiveRecord::Migration.select_all("select min(id) keep_id, GROUP_CONCAT(id) all_ids from users_buddies group by user_id, buddy_id, buddy_type having count(*) > 1").each do |row|
          ActiveRecord::Migration.execute "DELETE FROM users_buddies where id in (#{row['all_ids']}) and id != #{row['keep_id']}"
        end
      end
    rescue
      puts $!.message
      puts $!.backtrace.join "\n"
      self.down
      raise $!
    end



  end

  def self.down
    drop_table :external_users
    drop_table :dives_buddies
    drop_table :users_buddies
  end
end
