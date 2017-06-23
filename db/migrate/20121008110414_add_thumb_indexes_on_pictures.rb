class AddThumbIndexesOnPictures < ActiveRecord::Migration
  def self.up
    add_index(:pictures, :small_id)
    add_index(:pictures, :thumb_id)
    add_index(:pictures, :medium_id)
    add_index(:pictures, :large_id)
    add_index(:pictures, :original_image_id)
    add_index(:pictures, :original_video_id)
    add_index(:pictures, :webm)
    add_index(:pictures, :mp4)
  end

  def self.down
    remove_index(:pictures, :small_id)
    remove_index(:pictures, :thumb_id)
    remove_index(:pictures, :medium_id)
    remove_index(:pictures, :large_id)
    remove_index(:pictures, :original_image_id)
    remove_index(:pictures, :original_video_id)
    remove_index(:pictures, :webm)
    remove_index(:pictures, :mp4)
  end
end
