class DiveGear < ActiveRecord::Base
  extend FormatApi
  validates :category, :presence => true
  validates :category, :exclusion => { :in => [nil], :message => "category cannot be nil"}
  belongs_to :dive

  define_format_api :public => [:category, :id, :manufacturer, :model, :featured, :class => 'DiveGear'],
                    :private =>  [:category, :id, :manufacturer, :model, :featured, :class => 'DiveGear']

  define_api_updatable_attributes %w( category manufacturer model featured )

  def is_private_for?(options={})
    return true if self.dive.nil? || self.dive.user_id.nil?
    return true if options[:caller].id == self.dive.user_id rescue false
    return true if self.dive.user.is_private_for?(options) rescue false
    return false
  end

  def self.categories
    values = ['BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit']
    return values.sort
  end

  def category=(val)
    raise DBArgumentError.new "Invalid category", categories: DiveGear.categories unless DiveGear.categories.include?(val)
    write_attribute(:category, val)
  end

  def to_extended(arg)
    ext = DiveGearExtended.new self
    ext.featured = arg[:featured]
    return ext
  end

  def pref_order
    return 0
  end
end

