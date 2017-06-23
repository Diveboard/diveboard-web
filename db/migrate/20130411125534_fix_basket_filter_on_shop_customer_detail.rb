class FixBasketFilterOnShopCustomerDetail < ActiveRecord::Migration
  def self.up
    execute "create or replace view shop_customer_detail as
        select dives.shop_id, dives.user_id, 'Dive' stuff_type, dives.time_in registered_at, dives.id dive_id, null review_id, null basket_id, null message_id_from, null message_id_to
        from dives where privacy=0 and shop_id is not null and user_id is not null
      union all
        select reviews.shop_id, reviews.user_id, 'Review', reviews.created_at, null, reviews.id, null, null, null
        from reviews where anonymous=0
      union all
        select shop_id, user_id, 'Basket', IFNULL(baskets.paypal_order_date, baskets.created_at), null, null, baskets.id, null, null
        from baskets where status in ('paid', 'confirmed', 'hold', 'delivered', 'cancelled')
      union all
        select users.shop_proxy_id, from_id, 'InternalMessage', internal_messages.created_at,null, null, null, internal_messages.id, null
        from internal_messages, users
        where internal_messages.to_id = users.id
              and users.shop_proxy_id is not null
      union all
        select users.shop_proxy_id, to_id, 'InternalMessage', internal_messages.created_at, null, null, null, null, internal_messages.id
        from internal_messages, users
        where internal_messages.from_group_id = users.id
              and users.shop_proxy_id is not null"

  end

  def self.down
    execute "create or replace view shop_customer_detail as
        select dives.shop_id, dives.user_id, 'Dive' stuff_type, dives.time_in registered_at, dives.id dive_id, null review_id, null basket_id, null message_id_from, null message_id_to
        from dives where privacy=0 and shop_id is not null and user_id is not null
      union all
        select reviews.shop_id, reviews.user_id, 'Review', reviews.created_at, null, reviews.id, null, null, null
        from reviews where anonymous=0
      union all
        select shop_id, user_id, 'Basket', IFNULL(baskets.paypal_order_date, baskets.created_at), null, null, baskets.id, null, null
        from baskets where status in ('paid', 'delivered', 'cancelled')
      union all
        select users.shop_proxy_id, from_id, 'InternalMessage', internal_messages.created_at,null, null, null, internal_messages.id, null
        from internal_messages, users
        where internal_messages.to_id = users.id
              and users.shop_proxy_id is not null
      union all
        select users.shop_proxy_id, to_id, 'InternalMessage', internal_messages.created_at, null, null, null, null, internal_messages.id
        from internal_messages, users
        where internal_messages.from_group_id = users.id
              and users.shop_proxy_id is not null"

  end
end
