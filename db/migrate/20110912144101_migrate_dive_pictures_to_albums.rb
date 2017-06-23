class MigrateDivePicturesToAlbums < ActiveRecord::Migration
  def self.up
    execute "delete from picture_album_pictures"
    execute "insert into picture_album_pictures (picture_album_id, picture_id) select dive_id, id from pictures where dive_id is not null order by created_at"
    #execute "insert into picture_album_pictures (picture_album_id, picture_id, ordnum) select dive_id, id, unix_timestamp(created_at) from pictures where dive_id is not null"
    execute "update picture_album_pictures set ordnum=ordnum+1000 where picture_album_id in (select id from dives where favorite_picture is not null)"
    #execute "update picture_album_pictures set ordnum=1000-ordnum"
    execute "update picture_album_pictures set ordnum=0 where (picture_album_id, picture_id) in (select id, favorite_picture from dives where favorite_picture is not null)"
  end

  def self.down
    execute "delete from picture_album_pictures"
  end
end
