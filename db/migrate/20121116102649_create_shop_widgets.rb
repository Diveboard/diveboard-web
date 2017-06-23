class CreateShopWidgets < ActiveRecord::Migration
  def self.up
    create_table :shop_widgets do |t|
      t.integer :shop_id, :null => true
      t.string :widget_type, :null => false
      t.integer :widget_id, :null => false
      t.string :realm, :null => false
      t.string :set, :null => false
      t.integer :column, :null => false, :default => 0
      t.integer :position, :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :shop_widgets
  end
end
