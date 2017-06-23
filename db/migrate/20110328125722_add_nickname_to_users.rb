class AddNicknameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :nickname, :string
    add_column :users, :location, :string
    add_column :users, :gender, :boolean
    add_column :users, :birthday, :date
    
    ## fill in with default value
    User.all.each do |user|
      user.nickname = user.first_name+" "+user.last_name
      user.location = "blank"
      user.gender = "0"
      user.birthday = "2011-01-01".to_date
      user.save
    end
    
  end

  def self.down
    remove_column :users, :nickname
    remove_column :users, :location
    remove_column :users, :gender
    remove_column :users, :birthday
    
  end
end
