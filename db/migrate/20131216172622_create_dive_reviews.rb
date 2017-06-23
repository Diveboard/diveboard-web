class CreateDiveReviews < ActiveRecord::Migration
  def self.up
    create_table :dive_reviews do |t|
      t.integer :dive_id, :null => false
      t.string :name, :null => false
      t.integer :mark, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :dive_reviews
  end
end
