class DropTaxonomy < ActiveRecord::Migration
  def self.up
    drop_table :taxonomies
    drop_table :taxonomy_notes
  end

  def self.down
    create_table :taxonomies do |t|
      t.string   :name
      t.timestamps
    end
    create_table :taxonomy_notes do |t|
      t.string   :name
      t.timestamps
    end
  end

end
