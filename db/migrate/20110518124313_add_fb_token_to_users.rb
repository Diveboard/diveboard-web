class AddFbTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :fbtoken, :text
    #User.all.each do |u|
    #  token = u.token
    #  u.fbtoken = token
    #  u.save
    #end
    execute("UPDATE `users` set `fbtoken` = `token`")
    remove_column :users, :token
    add_column :users, :token, :string
    #add_index :users, [:token]
    User.all.each do |u|
      u.token = ActiveSupport::SecureRandom.base64(32)
      #if !u.email.nil?
      #  email = u.email.downcase
      #  u.email = email
      #end
      u.save!
    end
    
    #change_column :users, :id, :primary_key
    execute('ALTER TABLE `users` CHANGE `id` `id` int DEFAULT NULL auto_increment')
    remove_column :users, :password
    add_column :users, :password, :text
    
    #following columns are useless - let's get rid of them
    remove_column :users, :login
    remove_column :users, :gender 
    remove_column :users, :birthday
    #remove_column :users, :first_name
    #remove_column :users, :last_name
  end

  def self.down
    remove_column :users, :fbtoken
    add_column :users, :login, :string
    add_column :users, :gender, :integer 
    add_column :users, :birthday, :datetime
    #add_column :users, :first_name, :string
    #add_column :users, :last_name, :string
  end
end
