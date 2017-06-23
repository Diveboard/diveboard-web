class BasketItem < ActiveRecord::Base
  extend FormatApi
  belongs_to :good_to_sell
  delegate :shop_id, :to => :good_to_sell
  delegate :shop, :to => :good_to_sell
  delegate :realm, :to => :good_to_sell
  delegate :title, :to => :good_to_sell
  belongs_to :basket


  define_format_api :public => [:id, :title, :quantity, :line_price_after_tax_in_string],
                    :private =>  [:details, :deposit_option]

  before_save :ensure_good_currency_equal_shop_currency

  def deposit_option
    read_attribute(:deposit_option) && !good_to_sell.deposit.nil?
  end

  def price_before_tax
    if price then
      return Money.new(price*100, currency)
    else
      return good_to_sell.price_before_tax(deposit_option)
    end
  end

  def tax
    read_attribute(:tax) || good_to_sell.tax(deposit_option)
  end

  def tax_amount
    price_after_tax - price_before_tax
  end

  def price_after_tax
    if total then
      return Money.new(total*100, currency)
    else
      return good_to_sell.price_after_tax(deposit_option)
    end
  end

  def line_price_before_tax
    (self.price_before_tax * self.quantity)
  end

  def line_price_after_tax
    (self.price_after_tax * self.quantity)
  end

def line_price_after_tax_in_string
    if self.shop.currency_first
      self.shop.currency_symbol + (self.price_after_tax * self.quantity).to_s
    else
      (self.price_after_tax * self.quantity).to_s + self.shop.currency_symbol
    end
  end

  def remaining_after_deposit
    good_to_sell.price_after_tax(false) * self.quantity - line_price_after_tax
  end

  def line_tax_amount
    line_price_after_tax - line_price_before_tax
  end

  def details
    ActiveSupport::JSON.decode(read_attribute :details) rescue nil
  end

  def details=val
    write_attribute :details, ActiveSupport::JSON.encode(val)
  end

  def ensure_good_currency_equal_shop_currency
    raise DBArgumentError.new "Currency of good must be the same as the shop currency." if self.new_record? && !good_to_sell.can_be_sold?
  end

end
