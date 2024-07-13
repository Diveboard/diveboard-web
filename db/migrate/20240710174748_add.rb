class Add < ActiveRecord::Migration
  def up
    add_column :eolsnames, :eol_id, :integer
  end

  def down
    remove_column :eolsnames, :eol_id
  end
end
