class RenameIndexSignatures < ActiveRecord::Migration
  def up
    remove_index :signatures, name: 'dive_id'
    add_index :signatures, :dive_id
  end

  def down
    remove_index :signatures, :dive_id
    add_index :signatures, :dive_id, name: 'dive_id'
  end
end
