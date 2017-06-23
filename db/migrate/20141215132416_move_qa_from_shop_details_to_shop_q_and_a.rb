class MoveQaFromShopDetailsToShopQAndA < ActiveRecord::Migration
  def up
      questions_for_faq = ["staff", "boat", "shore_dives", "deco_chamber", "tanks", "gases", "gear", "gear_sales", "gear_maintenance", "services", "payment", "best_period", "hotels", "transfers", "parking", "other_activities"]
    ShopQAndA.reset_column_information
    ShopDetail.where("kind LIKE 'faq:%'").each do |d|
      ShopQAndA.create(question: d.kind[4..-1], answer: d.value, shop: d.shop, language: "en", official: false)
    end
    Shop.all.map(&:id).each do |s|
      questions_for_faq.each do |q|
        ShopQAndA.create(question: q, answer: "", shop_id: s, language: "en", official: true)
      end
    end
  end

  def down
    ShopQAndA.destroy_all
  end
end
