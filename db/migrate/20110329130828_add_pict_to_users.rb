class AddPictToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :pict, :boolean
  end

  def self.down
    remove_column :users, :pict
  end
end
