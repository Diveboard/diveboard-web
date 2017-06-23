module Widget

  def shop_owner
    ShopWidget.where(:widget_type => self.class.name, :widget_id => self.id).first.shop rescue nil
  end

  def update_widget *args
  end

  def empty_for? *args
    return false
  end
end
