class ChangePrecisionOfMaxDepthOnPicture < ActiveRecord::Migration
  def self.up
    change_column :dives, :maxdepth, :decimal, :precision => 8, :scale => 3
  end

  def self.down
    change_column :dives, :maxdepth, :decimal, :precision => 6, :scale => 3
  end
end
