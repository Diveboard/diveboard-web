class AddIndexOnFishFrequency < ActiveRecord::Migration
  def self.up
    add_index :fish_frequencies, :gbif_id
    add_index :fish_frequencies, [:lat, :lng, :count]
  end

  def self.down
    remove_index :fish_frequencies, :gbif_id
    remove_index :fish_frequencies, [:lat, :lng, :count]
  end
end
