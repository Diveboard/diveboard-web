class UpdateFbLikesStructure < ActiveRecord::Migration
  def self.up
    add_index :fb_likes, [:source_type, :source_id]
  end

  def self.down
  end
end
