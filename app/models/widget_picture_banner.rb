class WidgetPictureBanner < ActiveRecord::Base
  include Widget
  has_one :owner, :class_name => 'Shop'
  has_many :picture_album_pictures, :primary_key => 'album_id', :foreign_key => 'picture_album_id', :include => [:picture]
  belongs_to :album, :include => {:picture_album_pictures => :picture}



  def pictures
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture).to_ary
  end

  def picture_ids
    return picture_album_pictures.sort_by(&:ordnum).map(&:picture_id).to_ary
  end

  def pictures=(added_pictures)
    Picture.transaction {
      self.class.connection.execute("DELETE FROM picture_album_pictures WHERE picture_album_id = #{self.album_id}")
      args = []
      added_pictures.each do |pic|
        pic.save if pic.new_record?
        args.push "(#{self.album_id}, #{pic.id})"
      end
      self.class.connection.execute("INSERT INTO picture_album_pictures (picture_album_id, picture_id) VALUES #{ args.join(',') }") unless args.count == 0
    }
    return added_pictures
  end

  def update_widget data, shop
    if self.album_id.nil? then
      album = Album.create :user_id => shop.user_proxy.id, :kind => 'widget_picture_banner'
      self.album_id = album.id
      self.save
      self.reload
    end
    picture_ids = data['content']
    pictures = []
    picture_ids.each{|p| begin pictures.push(Picture.fromshake(p)) rescue nil end }
    self.pictures = pictures
  end

  def empty_for? mode
    if mode == :view
      return self.pictures.blank?
    elsif mode == :edit
      return false
    end
  end

end
