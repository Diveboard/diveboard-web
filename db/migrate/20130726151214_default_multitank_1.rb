class DefaultMultitank1 < ActiveRecord::Migration
  def self.up
    change_column :tanks, :multitank, :integer, :null => false, :default => 1
  end

  def self.down
    change_column :tanks, :multitank, :integer, :null => true, :default => nil
  end
end
