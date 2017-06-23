class CreateTaxonomyNotes < ActiveRecord::Migration
  def self.up
    create_table :taxonomy_notes do |t|
      t.string   :category
      t.string   :lang
      t.string   :note
      t.integer  :taxonomy_id
      t.timestamps
    end
  end

  def self.down
    drop_table :taxonomy_notes
  end
end
