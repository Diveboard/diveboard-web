class CreatePictureAlbums < ActiveRecord::Migration
  def self.up
    create_table :picture_album_pictures, :id => false, :options => 'ENGINE = MYISAM' do |t|
      t.integer :picture_album_id, :null => false
      t.integer :picture_id, :null => false
      t.integer :ordnum
    end

    execute "alter table picture_album_pictures ADD primary key (picture_album_id, ordnum)"
    execute "alter table picture_album_pictures change ordnum ordnum integer not null auto_increment"
    
  end

  def self.down
    drop_table :picture_album_pictures
  end
end
