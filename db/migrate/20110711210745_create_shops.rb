class CreateShops < ActiveRecord::Migration
  def self.up
    create_table :shops do |t|
      t.string :source
      t.string :source_id
      t.string :kind
      t.float  :lat
      t.float  :lng
      t.string :name
      t.text   :address
      t.string :email
      t.string :web
      t.string :phone
      t.text   :desc
      t.timestamps
    end
  end

  def self.down
    drop_table :shops
  end
end
