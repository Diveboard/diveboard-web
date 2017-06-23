class ShopCustomerHistory < ActiveRecord::Base
  extend FormatApi
  self.table_name = 'shop_customer_history'

  belongs_to :user
  belongs_to :shop
  belongs_to :stuff, :polymorphic => true

  delegate :to_api, :to => :stuff

  define_api_searchable_attributes ['shop_id', 'user_id', 'stuff_type']

  after_initialize :readonly!

end