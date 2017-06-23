class AddSurfaceIntervalToDives < ActiveRecord::Migration
  def change
    add_column :dives, :surface_interval, :integer
  end
end
