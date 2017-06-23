class AddDivetypeToDive < ActiveRecord::Migration
  def self.up
    add_column :dives, :divetype, :text
  end

  def self.down
    remove_column :dives, :divetype
  end
end
