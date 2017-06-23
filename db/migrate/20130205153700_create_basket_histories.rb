class CreateBasketHistories < ActiveRecord::Migration
  def self.up
    create_table :basket_histories do |t|
      t.integer :basket_id, :null => false
      t.string :new_status
      t.text :detail, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :basket_histories
  end
end
