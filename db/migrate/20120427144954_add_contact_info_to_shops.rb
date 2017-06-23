class AddContactInfoToShops < ActiveRecord::Migration
  def self.up
    remove_column :shops, :logo_url
    add_column :shops, :category, :string
    add_column :shops, :about_html, :text
    add_column :shops, :city, :string
    add_column :shops, :country_code, :string
    add_column :shops, :facebook, :string
    add_column :shops, :twitter, :string
    add_column :shops, :google_plus, :string
    add_column :shops, :openings, :text
    add_column :shops, :nearby, :text
  end

  def self.down
    add_column :shops, :logo_url, :text, :nil => true, :default => nil
    remove_column :shops, :category
    remove_column :shops, :about_html
    remove_column :shops, :city
    remove_column :shops, :country_code
    remove_column :shops, :facebook
    remove_column :shops, :twitter
    remove_column :shops, :google_plus
    remove_column :shops, :openings
    remove_column :shops, :nearby
  end
end
