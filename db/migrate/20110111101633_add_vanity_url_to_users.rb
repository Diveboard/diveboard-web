class AddVanityUrlToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :vanity_url, :string
  end

  def self.down
    remove_column :users, :vanity_url
  end
end
