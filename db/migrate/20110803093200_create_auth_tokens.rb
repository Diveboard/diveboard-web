class CreateAuthTokens < ActiveRecord::Migration
  def self.up
    create_table :auth_tokens do |t|
      t.string :token
      t.integer :user_id
      t.datetime :expires
      t.timestamps
    end
    User.all.each do |user|
      if !user.token.nil?
        #we migrate the token
        AuthTokens.create(:token => user.token, :expires => (Time.now+1.week), :user_id => user.id)
      end
    end
    remove_column :users, :token
  end

  def self.down
    drop_table :auth_tokens
    add_column :users, :token, :string
  end
end
