class CreateWikis < ActiveRecord::Migration
  def self.up
    create_table :wikis do |t|
      t.string :latest
      t.string :current
      t.string :name
      t.string :blob
      t.string :filename

      t.timestamps
    end
    add_column :spots, :wiki_id, :integer
  end

  def self.down
    drop_table :wikis
    remove_column :spots, :wiki_id
  end
end
