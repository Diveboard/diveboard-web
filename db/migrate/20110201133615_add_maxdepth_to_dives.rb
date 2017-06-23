class AddMaxdepthToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :maxdepth, :decimal, :precision => 6, :scale => 3
  end

  def self.down
    remove_column :dives, :maxdepth
  end
end
