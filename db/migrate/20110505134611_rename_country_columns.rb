class RenameCountryColumns < ActiveRecord::Migration
  def self.up
    rename_column :spots, :country, :country_code
  end

  def self.down
    rename_column :spots, :country_code, :country
  end
end
