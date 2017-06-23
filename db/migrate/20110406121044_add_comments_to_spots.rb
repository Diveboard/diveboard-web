class AddCommentsToSpots < ActiveRecord::Migration
  def self.up
    add_column :spots, :description, :text
  end

  def self.down
    remove_column :spots, :description
  end
end
