class WidgetText < ActiveRecord::Base
  include Widget
  has_one :owner, :class_name => 'Shop'

  def update_widget data, shop
    raise DBArgumentError.new 'Text is read only' if self.read_only
    self.content = data['content']
  end

  def modified?
    self.content != "Enter <b>some text</b> here."
  end

  def empty_for? mode
    if mode == :view
      return self.content.blank?
    elsif mode == :edit
      return !self.read_only
    end
  end
end
