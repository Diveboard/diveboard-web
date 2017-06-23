class CreateEolsnames < ActiveRecord::Migration
  def self.up
    create_table :eolsnames do |t|
      #"INSERT INTO `eolsnames` (`id`, `sname`, `taxon`, `data`, `picture`,`created_at`,`updated_at`)\n"
      t.string :sname
      t.text :taxon
      t.text :data
      t.integer :picture
      t.timestamps
    end
  end

  def self.down
    drop_table :eolsnames
  end
end
