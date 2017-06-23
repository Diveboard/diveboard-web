class WidgetReview
  include Widget
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :id, :shop_id, :shop, :user_proxy

  def self.find id, *args
    w = WidgetReview.new
    w.id = id
    w.shop_id = id
    w.shop = Shop.find(id) rescue nil
    w.user_proxy = w.shop.user_proxy rescue nil
    return w
  end

  def self.base_class
    return self
  end

  def destroyed?
    return false
  end

  def destroy
  end

  def new_record?
    return false
  end

  def save!
  end


  def reviews
    self.shop.reviews
  end


  def owner_id=val
    self.id = val
    self.shop_id = val
  end

  def owner_id
    self.shop_id
  end

  def shop_owner
    self.shop
  end

end
