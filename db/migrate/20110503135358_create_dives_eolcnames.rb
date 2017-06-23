class CreateDivesEolcnames < ActiveRecord::Migration
  def self.up
    create_table :dives_eolcnames, :id => false do |t|
      t.references :dive
      t.references :sname
      t.references :cname
    end
  end

  def self.down
    drop_table :dives_eolcnames
  end
end
