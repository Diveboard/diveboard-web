class ShopDetail < ActiveRecord::Base
  belongs_to :shop
  validates_uniqueness_of :kind, scope: [:value, :shop_id]
end
