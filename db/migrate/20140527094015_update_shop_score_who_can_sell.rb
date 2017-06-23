class UpdateShopScoreWhoCanSell < ActiveRecord::Migration
  def up
    Shop.where('paypal_id is not null').each do |shop|
      shop.save if shop.can_sell?
    end
  end

  def down
  end
end
