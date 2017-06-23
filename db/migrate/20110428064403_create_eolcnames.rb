class CreateEolcnames < ActiveRecord::Migration
  def self.up
    create_table :eolcnames do |t|
        #"INSERT INTO `eolcnames` (`eol_sname_id`, `cname`, `language`, `eol_preferred`,`created_at`,`updated_at`)\n"
      t.integer :eol_sname_id
      t.string :cname
      t.string :language
      t.boolean :eol_preferred  
      t.timestamps
    end
  end

  def self.down
    drop_table :eolcnames
  end
end
