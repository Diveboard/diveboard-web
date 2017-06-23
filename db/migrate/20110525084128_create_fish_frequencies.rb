class CreateFishFrequencies < ActiveRecord::Migration
  def self.up
    create_table :fish_frequencies do |t|
      t.integer :gbif_id
      t.integer :lat
      t.integer :lng
      t.integer :count
      t.timestamps
    end
  end

  def self.down
    drop_table :fish_frequencies
  end
end
