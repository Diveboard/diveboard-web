class ShopWidget < ActiveRecord::Base
  belongs_to :shop, :inverse_of => :shop_widgets
  belongs_to :widget, :polymorphic => true

  alias :widget_active :widget

  def self.copy_set set_from, shop_id, set_version
    result_set = [];
    ShopWidget.transaction do
      ShopWidget.where(:shop_id => shop_id, :set => set_version).each &:destroy
      set_from.each do |shop_w|
        if shop_w.widget.respond_to? :attributes
          new_widget = shop_w.widget.class.new shop_w.widget.attributes
        else
          new_widget = shop_w.widget.class.new
        end
        new_widget.owner_id = shop_id if new_widget.respond_to? :owner_id
        new_widget.save!
        new_sw = ShopWidget.new shop_w.attributes
        new_sw.shop_id = shop_id
        new_sw.widget = new_widget
        new_sw.set = set_version
        new_sw.save!
        result_set.push new_sw
      end
    end
    return result_set
  end

  def widget
    return WidgetReview.find(widget_id) if widget_type == 'WidgetReview'
    widget_active
  end

end
