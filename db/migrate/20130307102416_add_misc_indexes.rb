class AddMiscIndexes < ActiveRecord::Migration
  def self.up
    add_index :users, :email
    add_index :dives, :trip_id
    add_index :dives_fish, :dive_id
    add_index :dives_fish, :fish_id
    add_index :blog_posts, [:user_id, :published_at]
    add_index :tanks, [:dive_id, :order]
    add_index :dive_gears, :dive_id
    add_index :user_gears, :user_id
    add_index :dive_using_user_gears, :user_gear_id
    add_index :dive_using_user_gears, :dive_id
    add_index :pictures_eolcnames, :picture_id
    add_index :pictures_eolcnames, :sname_id
    add_index :pictures_eolcnames, :cname_id
    add_index :memberships, [:user_id, :role]
    add_index :memberships, [:group_id, :role]
    add_index :shop_widgets, [:shop_id, :set, :realm, :position]
    add_index :goods_to_sell, [:shop_id, :realm, :status, :order_num], :name => :goods_to_sell_on_shop_id
    add_index :wikis, :album_id
  end

  def self.down
    remove_index :users, :email
    remove_index :dives, :trip_id
    remove_index :dives_fish, :dive_id
    remove_index :dives_fish, :fish_id
    remove_index :blog_posts, [:user_id, :published_at]
    remove_index :tanks, [:dive_id, :order]
    remove_index :dive_gears, :dive_id
    remove_index :user_gears, :user_id
    remove_index :dive_using_user_gears, :user_gear_id
    remove_index :dive_using_user_gears, :dive_id
    remove_index :pictures_eolcnames, :picture_id
    remove_index :pictures_eolcnames, :sname_id
    remove_index :pictures_eolcnames, :cname_id
    remove_index :memberships, [:user_id, :role]
    remove_index :memberships, [:group_id, :role]
    remove_index :shop_widgets, [:shop_id, :set, :realm, :position]
    remove_index :goods_to_sell, :name => :goods_to_sell_on_shop_id
    remove_index :wikis, :album_id
  end
end
