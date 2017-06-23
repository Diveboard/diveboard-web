class ShopCustomer < ActiveRecord::Base
  extend FormatApi

  belongs_to :user
  belongs_to :shop
  belongs_to :review

  define_format_api :public => [ :user_id, :user_shaken_id, :shop_id, :review, :dive_count, :basket_count, :message_to_count, :message_from_count],
    :for_shop => [:user],
    :for_user => [:shop]

  define_api_searchable_attributes ['shop_id', 'user_id',
    'user_nickname' => {:join => :user, :key => 'users.nickname'},
  ]

  after_initialize :readonly!

  def user_shaken_id
    return user.shaken_id
  end

end