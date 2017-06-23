require 'money'

class GoodToSell < ActiveRecord::Base
  extend FormatApi
  self.table_name = 'goods_to_sell'
  belongs_to :shop
  default_scope where("status <> 'deleted'")

  before_save :ensure_currency

  define_format_api :public => [:id, :shop_id, :title, :price, :total, :currency, :currency_symbol, :tax, :deposit, :realm, :cat1, :cat2 ],
                    :detailed => [:description],
                    :private =>  []


  define_api_private_attributes :stock_type, :stock_id, :stock

  define_api_updatable_attributes %w(shop_id order_num title description price total tax currency deposit realm cat1 cat2 cat3)

  def is_private_for?(options={})
    return true if self.shop_id.nil?
    return true if self.shop.is_private_for?(options) rescue false
    return false
  end

  def realm=val
    write_attribute(:realm, val)
    write_attribute(:cat1, nil)
    write_attribute(:cat2, nil)
    write_attribute(:cat3, nil)
  end

  def cat1=val
    write_attribute(:cat1, val)
    write_attribute(:cat2, nil)
    write_attribute(:cat3, nil)
  end

  def cat2=val
    write_attribute(:cat2, val)
    write_attribute(:cat3, nil)
  end

  def cat3=val
    write_attribute(:cat3, val)
  end

  def price_after_tax(deposit_option=false)
    return Money.new(deposit*100, currency) if !deposit.nil? && deposit_option
    return nil if total.nil?
    return Money.new(total*100, currency)
  end

  def price_before_tax(deposit_option=false)
    if !deposit.nil? && deposit_option then
      if price.nil? || total.nil? then
        return nil
      else
        return Money.new((deposit*price/total)*100, currency)
      end
    elsif price.nil? then
      return nil
    else
      return Money.new(price*100, currency)
    end
  end

  def tax(deposit_option=false)
    t = read_attribute(:tax)
    if !deposit.nil? && deposit_option then
      if t.nil? || total.nil? then
        return nil
      else
        return Money.new((deposit*t/total)*100, currency)
      end
    else
      return t
    end
  end

  def currency_symbol
    ensure_currency
    return Money::Currency.find(self.currency).symbol
  end

  def destroy
    self.status = 'deleted'
    self.save
  end

  def delete
    self.status = 'deleted'
    self.save
  end

  def can_be_sold?
    return false if self.price.nil? || self.total.nil?
    return false unless self.currency == self.shop.currency
    return false unless self.price > 0 && self.total > 0
    return true
  end

private
  def ensure_currency
    begin
      self.currency = self.shop.currency if self.currency.nil?
    rescue
      self.currency = 'USD'
    end
  end

end
