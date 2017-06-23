class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.integer :user_id, :null => false
      t.integer :shop_id, :null => false
      t.boolean :anonymous, :null => false, :default => false
      t.boolean :recommend, :null => false
      t.integer :mark_orga
      t.integer :mark_friend
      t.integer :mark_secu
      t.integer :mark_boat
      t.integer :mark_rent
      t.text :title
      t.text :comment
      t.text :service
      t.boolean :spam, :null => false, :default => false
      t.boolean :reported_spam, :null => false, :default => false
      t.boolean :flag_moderate, :null => false, :default => true
      t.timestamps
    end
    change_column :reviews, :service, "ENUM('autonomous', 'guide', 'training', 'snorkeling', 'fill', 'other')", :null => false
  end

  def self.down
    drop_table :reviews
  end
end
