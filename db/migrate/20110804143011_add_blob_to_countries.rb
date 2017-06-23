class AddBlobToCountries < ActiveRecord::Migration
  def self.up
    add_column :countries, :blob, :string
    Country.all.each do |country|
      country.blob = country.cname.to_url
      country.save
    end
  end

  def self.down
    remove_column :countries, :blob
  end
end
