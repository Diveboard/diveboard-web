class AddSkippedDivesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :skip_import_dives, :text, :limit => 65536
  end

  def self.down
    remove_column :users, :skip_import_dives
  end
end
