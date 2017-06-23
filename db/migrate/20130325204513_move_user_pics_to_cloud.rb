class MoveUserPicsToCloud < ActiveRecord::Migration
  def self.up
    ## will add additional fields on the User table
    change_column :albums, :kind, "ENUM('dive', 'wallet', 'trip', 'blog', 'shop_ads', 'avatar')", :null => false
    User.all.each do |u|
      if u.pict
        avatar_path = "public/user_images/#{u.id}.png"
        avatar_image = Picture.create_image({:path => avatar_path, :user_id => u.id})
        avatar_image.append_to_album u.avatars.id
      end
    end
  end

  def self.down
  end
end
