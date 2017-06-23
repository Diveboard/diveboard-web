class RenameIndexGbif < ActiveRecord::Migration
  def up
    remove_index :gbif_ipts, name: 'dive_id'
    remove_index :gbif_ipts, name: 'eol_id'
    add_index :gbif_ipts, :dive_id
    add_index :gbif_ipts, :eol_id
  end

  def down
    remove_index :gbif_ipts, :dive_id 
    remove_index :gbif_ipts, :eol_id
    add_index :gbif_ipts, :dive_id, name: 'dive_id'
    add_index :gbif_ipts, :eol_id, name: 'eol_id'
  end
end
