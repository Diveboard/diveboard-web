class CreateShopCustomerHistory < ActiveRecord::Migration
  def self.up
    add_index :baskets, [:user_id, :shop_id, :paypal_order_date]
    add_index :baskets, [:shop_id, :user_id, :paypal_order_date]



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


    execute "create or replace view shop_customers as
      select shop_id + user_id*1000000 id, shop_id, user_id, count(dive_id) dive_count, max(review_id) review_id, count(basket_id) basket_count, count(message_id_to) message_to_count, count(message_id_from) message_from_count
      from shop_customer_detail
      group by shop_id, user_id"

    execute "create or replace view shop_customer_history as
      select shop_id, user_id, registered_at, stuff_type,
        CASE stuff_type WHEN 'Dive' THEN dive_id
          WHEN 'Review' THEN review_id
          WHEN 'Basket' THEN basket_id
          WHEN 'InternalMessage' THEN IFNULL(message_id_from, message_id_to)
          ELSE NULL
        END as stuff_id
        FROM shop_customer_detail"


  end

  def self.down
    remove_index :baskets, [:user_id, :shop_id, :paypal_order_date]
    remove_index :baskets, [:shop_id, :user_id, :paypal_order_date]

    execute "DROP VIEW shop_customer_history"

    execute "create or replace view shop_customer_detail as
        select dives.shop_id, dives.user_id, dives.id dive_id, null review_id, null basket_id, null message_id_from, null message_id_to
        from dives where privacy=0 and shop_id is not null and user_id is not null
      union all
        select reviews.shop_id, reviews.user_id, null, reviews.id, null, null, null
        from reviews where anonymous=0
      union all
        select shop_id, user_id, null, null, baskets.id, null, null
        from baskets where status in ('paid', 'delivered', 'cancelled')
      union all
        select users.shop_proxy_id, from_id, null, null, null, internal_messages.id, null
        from internal_messages, users
        where internal_messages.to_id = users.id
              and users.shop_proxy_id is not null
      union all
        select users.shop_proxy_id, to_id, null, null, null, null, internal_messages.id
        from internal_messages, users
        where internal_messages.from_group_id = users.id
              and users.shop_proxy_id is not null"


    execute "create or replace view shop_customers as
      select shop_id + user_id*1000000 id, shop_id, user_id, count(dive_id) dive_count, max(review_id) review_id, count(basket_id) basket_count, count(message_id_to) message_to_count, count(message_id_from) message_from_count
      from shop_customer_detail
      group by shop_id, user_id"

  end
end
