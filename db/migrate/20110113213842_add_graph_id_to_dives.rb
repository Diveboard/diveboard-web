class AddGraphIdToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :graph_id, :string
  end

  def self.down
    remove_column :dives, :graph_id
  end
end
