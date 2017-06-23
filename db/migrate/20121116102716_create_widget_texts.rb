class CreateWidgetTexts < ActiveRecord::Migration
  def self.up
    create_table :widget_texts do |t|
      t.text :content
      t.boolean :read_only, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :widget_texts
  end
end
