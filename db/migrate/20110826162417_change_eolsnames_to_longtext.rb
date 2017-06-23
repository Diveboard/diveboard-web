class ChangeEolsnamesToLongtext < ActiveRecord::Migration
  def self.up
    change_column :eolsnames, :data, :longtext
  end

  def self.down
    change_column :eolsnames, :data, :text
  end
end
