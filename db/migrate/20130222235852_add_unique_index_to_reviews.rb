class AddUniqueIndexToReviews < ActiveRecord::Migration
  def self.up
    add_index :reviews, [:user_id, :shop_id], :unique => true
    add_index :reviews, [:shop_id, :created_at]
  end

  def self.down
    remove_index :reviews, [:user_id, :shop_id]
    remove_index :reviews, [:shop_id, :created_at]
  end
end
