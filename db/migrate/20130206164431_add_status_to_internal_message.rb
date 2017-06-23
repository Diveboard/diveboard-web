class AddStatusToInternalMessage < ActiveRecord::Migration
  def self.up
    add_column :internal_messages, :status, :string, :null => false, :default => 'new'
  end

  def self.down
    remove_column :internal_messages, :status
  end
end
