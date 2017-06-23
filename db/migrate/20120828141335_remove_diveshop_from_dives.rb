class RemoveDiveshopFromDives < ActiveRecord::Migration
  def self.up
    Dive.where("diveshop is not null and shop_id is null").reject{|d| d.diveshop.blank?}.each do |d|
      ##only dives with no shop id but data in the diveshop field
      d.diveshop = JSON.parse(d.read_attribute(:diveshop))
    end
    remove_column :dives, :diveshop
  end

  def self.down
    add_column :dives, :diveshop, :string
    Dive.all.each do |d|
      if !d.guide.blank? || !d.diveshop.blank?
        data = d.diveshop
        data["guide"] = d.guide
        d.write_attribute(:diveshop, data)
        d.save
      end
    end
  end
end