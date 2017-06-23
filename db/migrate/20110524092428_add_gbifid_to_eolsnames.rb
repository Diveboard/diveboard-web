class AddGbifidToEolsnames < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :gbif_id, :integer
  end

  def self.down
    remove_column :eolsnames, :gbif_id
  end
end
