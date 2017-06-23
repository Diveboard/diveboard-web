class CreateTanks < ActiveRecord::Migration
  def self.up
    create_table :tanks do |t|
      t.float :p_start
      t.float :p_end
      t.integer :time_start
      t.integer :o2
      t.integer :n2
      t.integer :he
      t.float :volume
      t.integer :dive_id
      t.integer :order
      t.timestamps
    end
    add_column :tanks, :material, "ENUM('aluminium', 'steel')"
    add_column :tanks, :gas, "ENUM('air', 'EANx32', 'EANx36', 'EANx40', 'custom')"
    
  end

  def self.down
    drop_table :tanks
  end
end
