class AddFbPublishInfoToDives < ActiveRecord::Migration
  def self.up
    add_column :dives, :graph_lint, :datetime
  end

  def self.down
    remove_column :dives, :graph_lint
  end
end
