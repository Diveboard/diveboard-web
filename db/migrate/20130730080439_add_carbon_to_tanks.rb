class AddCarbonToTanks < ActiveRecord::Migration
  def self.up
    change_column :tanks, :material, "ENUM('aluminium', 'steel', 'carbon')"
  end

  def self.down
    change_column :tanks, :material, "ENUM('aluminium', 'steel')"
  end
end
