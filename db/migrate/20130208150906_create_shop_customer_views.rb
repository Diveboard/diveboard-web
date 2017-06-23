class CreateShopCustomerViews < ActiveRecord::Migration
  def self.up
    execute "create or replace view shop_customer_detail as
        select dives.shop_id, dives.user_id, dives.id dive_id, null review_id, null basket_id, null message_id
        from dives where privacy=0 and shop_id is not null and user_id is not null
      union all
        select reviews.shop_id, reviews.user_id, null, reviews.id, null, null
        from reviews where anonymous=0
      union all
        select shop_id, user_id, null, null, baskets.id, null
        from baskets where status in ('paid', 'delivered', 'cancelled')
      union all
        select users.shop_proxy_id, from_id, null, null, null, internal_messages.id
        from internal_messages, users
        where internal_messages.to_id = users.id
              and users.shop_proxy_id is not null"

    execute "create or replace view shop_customers as
      select shop_id + user_id*1000000 id, shop_id, user_id, count(dive_id) dive_count, max(review_id) review_id, count(basket_id) basket_count, count(message_id) message_to_count
      from shop_customer_detail
      group by shop_id, user_id"
  end

  def self.down
    execute "DROP VIEW shop_customers"
    execute "DROP VIEW shop_customer_detail"
  end
end
