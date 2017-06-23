class AddActiveToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :active, :boolean, default: false
    Area.reset_column_information
    Rake::Task["area:active"].execute
  end
end
