class AddNotesToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :notes, :text
  end

  def self.down
    remove_column :dives, :notes
  end
end
