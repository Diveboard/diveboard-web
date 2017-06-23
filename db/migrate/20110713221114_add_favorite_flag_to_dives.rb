class AddFavoriteFlagToDives < ActiveRecord::Migration
  def self.up
     add_column :dives, :favorite, :boolean
  end

  def self.down
     remove_column :dives, :favorite
  end
end
