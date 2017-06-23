class CreateModHistories < ActiveRecord::Migration
  def self.up
    create_table :mod_histories do |t|
      t.integer :obj_id
      t.string :table
      t.integer :operation # (1=update 0=delete)
      t.text :before #in json
      t.text :after #in json
      t.timestamps
    end
  end

  def self.down
    drop_table :mod_histories
  end
end
