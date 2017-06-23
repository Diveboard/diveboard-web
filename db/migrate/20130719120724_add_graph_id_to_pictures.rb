class AddGraphIdToPictures < ActiveRecord::Migration
  def self.up
    add_column :pictures, :fb_graph_id, :string
  end

  def self.down
    remove_column :pictures, :fb_graph_id
  end
end
