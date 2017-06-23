class AddMultitankToTanks < ActiveRecord::Migration
  def self.up
    add_column :tanks, :multitank, :integer
    Tank.all.each do |t|
      t.multitank = 1
      t.save
    end
  end

  def self.down
    remove_column :tanks, :multitank
  end
end
