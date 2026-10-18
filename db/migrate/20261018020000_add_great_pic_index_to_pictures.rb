# The homepage cover picks the latest "great" pictures (great_pic = true ORDER BY updated_at).
# Without this index MySQL walked the updated_at index through most of the pictures table on
# every homepage view (~1.3s). The index was added directly in production on 2026-10-18
# (online, ALGORITHM=INPLACE), so `up` skips it when it already exists.
class AddGreatPicIndexToPictures < ActiveRecord::Migration
  INDEX_NAME = 'index_pictures_on_great_pic_and_updated_at'

  def up
    unless index_exists?(:pictures, [:great_pic, :updated_at], :name => INDEX_NAME)
      add_index :pictures, [:great_pic, :updated_at], :name => INDEX_NAME
    end
  end

  def down
    remove_index :pictures, :name => INDEX_NAME
  end
end
