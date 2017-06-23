class CreateWidgetPicture < ActiveRecord::Migration
  def self.up
    create_table :widget_picture_banners do |t|
      t.integer :album_id
      t.timestamps
    end
  end

  def self.down
    drop_table :widget_picture_banners
  end
end
