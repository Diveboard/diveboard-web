class CreateWidgetListDives < ActiveRecord::Migration
  def self.up
    create_table :widget_list_dives do |t|
      t.integer :owner_id, :null => true
      t.string :from_type, :null => false
      t.integer :from_id, :null => false
      t.integer :limit, :null => false, :default => 10
      t.timestamps
    end
  end

  def self.down
    drop_table :widget_list_dives
  end
end
