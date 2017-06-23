class CreateTaxonomies < ActiveRecord::Migration
  def self.up
    create_table :taxonomies do |t|
      t.string   :name
      t.string   :displayname
      t.string   :authority
      t.integer  :taxonomy_parent
      t.integer  :rank
      t.integer  :acctaxon
      t.integer  :status
      t.string   :unacceptreason
      t.integer  :marine
      t.integer  :brackish
      t.integer  :fresh
      t.integer  :terrestrial
      t.integer  :fossil
      t.integer  :hidden
      t.string   :hierarchy
      t.timestamps
    end
  end

  def self.down
    drop_table :taxonomies
  end
end
