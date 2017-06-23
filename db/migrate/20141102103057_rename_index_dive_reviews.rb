class RenameIndexDiveReviews < ActiveRecord::Migration
  def up
    remove_index :dive_reviews, name: 'dive_id'
    add_index :dive_reviews, :dive_id
  end

  def down
    remove_index :dive_reviews, :dive_id
    add_index :dive_reviews, :dive_id, name: 'dive_id'
  end
end
