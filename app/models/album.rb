class Album < ActiveRecord::Base

  has_many :picture_album_pictures, :foreign_key => 'picture_album_id', :include => [:picture]
  has_one :dive

  def pictures
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture).reject(&:nil?).to_ary
  end

  def delete(picture_id)
    ##remove picture with id from album
    PictureAlbumPicture.where(:picture_album_id => self.id).where(:picture_id => picture_id).each do |e|
      e.destroy
    end
  end

  def empty!
    ##will empty the album
    PictureAlbumPicture.where(:picture_album_id => self.id).each do |e|
      e.destroy
    end
  end

  def picture_ids
    return pictures.map(&:id)
  end

  def self.orphans
    Album.joins(' LEFT JOIN dives ON dives.album_id = albums.id ').where(:kind => 'dive').where('dives.id is null')
    Album.joins(' LEFT JOIN trips ON trips.album_id = albums.id ').where(:kind => 'trip').where('trips.id is null')
    Album.joins(' LEFT JOIN users ON users.id = albums.user_id ').where(:kind => 'certifs').where('users.id is null')
  end

end
