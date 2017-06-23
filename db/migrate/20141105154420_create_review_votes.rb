class CreateReviewVotes < ActiveRecord::Migration
  def change
    create_table :review_votes do |t|
      t.integer :user_id, null: false
      t.integer :review_id, null: false
      t.boolean :vote, null: false
      t.timestamps
    end

    add_index :review_votes, [:review_id, :vote]
    add_index :review_votes, [:user_id, :review_id]
  end
end
