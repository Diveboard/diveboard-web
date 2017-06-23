class EnsureUserIdInPictures < ActiveRecord::Migration
  def self.up
    Picture.where(:user_id => nil).each do |pic|
      begin
        pic.user_id = pic.user.id
        pic.save
      rescue
      end
    end
  end

  def self.down
  end
end
