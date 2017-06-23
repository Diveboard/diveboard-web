class RemoveFullcnameFromSpots < ActiveRecord::Migration
  def self.up
    remove_column :spots, :fullcname
  end

  def self.down
    add_column :spots, :fullcname, :string
  end
end
