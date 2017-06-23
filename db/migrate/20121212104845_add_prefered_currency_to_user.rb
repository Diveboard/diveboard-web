class AddPreferedCurrencyToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :currency, :string
  end

  def self.down
    remove_column :users, :currency
  end
end
