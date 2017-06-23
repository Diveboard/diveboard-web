class AddReplyToReviews < ActiveRecord::Migration
  def self.up
    add_column :reviews, :reply, :text
  end

  def self.down
    remove_column :reviews, :reply
  end
end
