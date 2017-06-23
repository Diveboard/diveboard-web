class WidgetListDives < ActiveRecord::Base
  include Widget
  belongs_to :owner, :class_name => 'Shop'
  belongs_to :from, :polymorphic => true


  def owner_id=val
    write_attribute :owner_id, val
    write_attribute :from_id, val
    write_attribute :from_type, 'Shop'
  end


end
