class PictureAlbumPicture < ActiveRecord::Base
  require 'composite_primary_keys'
  set_primary_keys :picture_album_id, :picture_id
  belongs_to :dive, :foreign_key => :picture_album_id, :primary_key => :album_id
  belongs_to :album, :foreign_key => :picture_album_id
  belongs_to :picture
  belongs_to :wiki, :foreign_key => :picture_album_id, :primary_key => :album_id
end
