class ProfileData < ActiveRecord::Base
  extend FormatApi

  belongs_to :dive, :inverse_of => :raw_profile
  define_format_api :public => [ :seconds, :depth, :current_water_temperature, :main_cylinder_pressure, :heart_beats, :deco_violation, :deco_start, :ascent_violation, :bookmark, :surface_event ],
  :private => []

  define_api_includes :private => [:public], :mobile => [:private], :search_full => [:search_light, :public]
  define_api_updatable_attributes %w( seconds depth current_water_temperature main_cylinder_pressure heart_beats deco_violation deco_start ascent_violation bookmark surface_event ) ###TODO: remove user_id from there


  def is_private_for?(options = {})
    begin
      return true if self.dive_id.nil? #well.... not really....
      return true if options[:private]
      return true if options[:caller].id == self.dive.user_id rescue false
      return true if self.dive.is_private_for?(options) rescue false
      return false
    rescue
      return false
    end
  end


end
