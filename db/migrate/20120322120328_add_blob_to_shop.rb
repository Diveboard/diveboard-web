class AddBlobToShop < ActiveRecord::Migration
  def self.up
    add_column :shops, :shop_vanity, :string, :null => true 
    Shop.transaction do
      Shop.all.each do |shop|
        shop.shop_vanity = ActiveSupport::Inflector.transliterate(shop.name).downcase.gsub(/[ ,&:@+\t-*!]+/,'-').gsub(/[^a-z0-9_-]/, '').gsub(/-+/,'-') unless shop.name.nil?
        shop.save
      end 
    end
  end

  def self.down
    remove_column :shops, :shop_vanity
  end
end
