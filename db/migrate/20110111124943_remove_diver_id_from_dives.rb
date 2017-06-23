class RemoveDiverIdFromDives < ActiveRecord::Migration
  def self.up
        remove_column :dives, :diver_id
  end

  def self.down
  end
end
