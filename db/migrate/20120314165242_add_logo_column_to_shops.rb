class AddLogoColumnToShops < ActiveRecord::Migration
  def self.up
    add_column :shops, :logo_url, :text, :nil => true, :default => nil
  end

  def self.down
    remove_column :shops, :logo_url
  end
end
