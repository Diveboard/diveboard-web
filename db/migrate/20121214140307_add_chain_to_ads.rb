class AddChainToAds < ActiveRecord::Migration
  def self.up
    add_column :advertisements, :moderate_id, :integer
  end

  def self.down
    remove_column :advertisements, :moderate_id
  end
end
