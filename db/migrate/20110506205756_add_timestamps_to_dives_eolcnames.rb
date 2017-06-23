class AddTimestampsToDivesEolcnames < ActiveRecord::Migration
  def self.up
    change_table(:dives_eolcnames) do |t|
      t.timestamps
    end 
  end

  def self.down
    t.remove :created_at
    t.remove :updated_at
  end
end
