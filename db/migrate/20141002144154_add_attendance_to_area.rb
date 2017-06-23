class AddAttendanceToArea < ActiveRecord::Migration
  def change
    add_column :areas, :january, :integer
    add_column :areas, :february, :integer
    add_column :areas, :march, :integer
    add_column :areas, :april, :integer
    add_column :areas, :may, :integer
    add_column :areas, :june, :integer
    add_column :areas, :july, :integer
    add_column :areas, :august, :integer
    add_column :areas, :september, :integer
    add_column :areas, :october, :integer
    add_column :areas, :november, :integer
    add_column :areas, :december, :integer
  end
end
