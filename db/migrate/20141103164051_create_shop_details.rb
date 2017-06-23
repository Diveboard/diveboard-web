class CreateShopDetails < ActiveRecord::Migration
  def up
    create_table :shop_details, :options => 'DEFAULT CHARSET=utf8' do |t|
      t.string :kind
      t.string :value, :limit => 4096
      t.references :shop

      t.timestamps
    end
    add_index :shop_details, :shop_id
    ShopDetail.reset_column_information
    Shop.all.map(&:id).each do |shop_id| 
      s = Shop.find_by_id shop_id
      if !s.country.nil?
        ShopDetail.create(kind: "lang", value: s.country.ccode, shop: s)
      end
      if !s.source.nil? && s.source != "DIVEBOARD" && !s.source.blank?
        ShopDetail.create(kind: "affiliation", value: s.source, shop: s)
      end
      s.owners.each do |owner|
        if !owner.first_name.nil? && !owner.last_name.nil?
          ShopDetail.create(kind: "team", value: owner.first_name + " " + owner.last_name, shop: s)
        elsif !owner.nickname.nil?
          ShopDetail.create(kind: "team", value: owner.nickname, shop: s)
        end
      end
    end
  end

  def self.down
    drop_table :shop_details
  end
end
