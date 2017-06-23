class InitializeShopWidgets4home < ActiveRecord::Migration
  def self.up

    pic = WidgetPictureBanner.create
    txt = WidgetText.create :content => "Enter <b>some text</b> here.", :read_only => false


    ShopWidget.create :widget_type => 'WidgetPictureBanner',
      :widget_id => pic.id,
      :realm => 'home',
      :set => 'default',
      :column => 0,
      :position => 0

    ShopWidget.create :widget_type => 'WidgetText',
      :widget_id => txt.id,
      :realm => 'home',
      :set => 'default',
      :column => 0,
      :position => 1

  end

  def self.down
    ShopWidget.where(:set => 'default').each do |shop_widget|
      shop_widget.widget.destroy
      shop_widget.destroy
    end
  end
end
