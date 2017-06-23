class CreateDiveFish < ActiveRecord::Migration
  def self.up
    create_table :dives_fish, :id => false do |t| 
      t.references :dive 
      t.references :fish
    end
  end

  def self.down
    drop_table :dives_fish
  end
end
