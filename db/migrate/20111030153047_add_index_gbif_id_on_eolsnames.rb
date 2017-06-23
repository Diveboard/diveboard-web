class AddIndexGbifIdOnEolsnames < ActiveRecord::Migration
  def self.up
    add_index :eolsnames, :gbif_id
  end

  def self.down
    remove_index :eolsnames, :gbif_id
  end
end
