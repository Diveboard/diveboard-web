class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.integer :user_id, :null => false
      t.integer :group_id, :null => false
      t.string :role, :null => false
      t.timestamps
    end
    change_column :memberships, :role, "ENUM('admin', 'member')", :null => false
  end

  def self.down
    drop_table :memberships
  end
end
