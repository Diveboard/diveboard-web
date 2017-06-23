class AddFlagToEolsnames < ActiveRecord::Migration
  def self.up
    add_column :eolsnames, :has_occurences, :boolean, :nulle => false, :default => false
    execute "UPDATE eolsnames set has_occurences = 1"
  end

  def self.down
    remove_column :eolsnames, :has_occurences
  end
end
