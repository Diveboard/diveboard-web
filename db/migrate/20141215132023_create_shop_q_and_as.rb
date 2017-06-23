class CreateShopQAndAs < ActiveRecord::Migration
  def change
    create_table :shop_q_and_as, :options => 'DEFAULT CHARSET=utf8' do |t|
      t.references :shop
      t.string :question
      t.string :answer
      t.string :language, :limit => 3
      t.boolean :official, :default => false
      t.integer :position
      t.timestamps
    end
  end
end
