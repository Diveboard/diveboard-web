class UpdateOldPictureOrdnum < ActiveRecord::Migration
  def self.up
    execute "update picture_album_pictures set ordnum = 1 where ordnum=0"
  end

  def self.down
  end
end
