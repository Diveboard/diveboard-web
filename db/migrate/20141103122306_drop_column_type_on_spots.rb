class DropColumnTypeOnSpots < ActiveRecord::Migration
  def up
    remove_column :spots, :type
  end

  def down
    add_column :spots, :type, :integer, after: :zoom
  end
end
