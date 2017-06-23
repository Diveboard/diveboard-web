class LinkDiveToShops < ActiveRecord::Migration
  def self.up
    add_column :dives, :shop_id, :integer, :nil => true, :default => nil rescue nil
    add_column :dives, :guide, :string, :nil => true, :default => nil rescue nil
    Dive.all.each do |dive|
      next if dive.diveshop.nil?

      # migrating the guide value
      begin
        dive.guide = dive.diveshop['guide'] unless dive.diveshop.nil?
        dive.save unless dive.diveshop.nil?
      rescue
      end

      #trying to find the shop
      name = dive.diveshop['name'] rescue nil
      next if name.blank?
      shops = Shop.where(:name => name)
      puts "#{dive.id}\t#{shops.count}\t#{name}" if shops.count != 1
      next if shops.count != 1
      dive.shop_id = shops.first.id
      dive.save
    end;nil
  end

  def self.down
    remove_column :dives, :shop_id
    remove_column :dives, :guide
  end
end
