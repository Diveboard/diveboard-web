=begin
class Module
  remove_method :yaml_as rescue nil
  alias :yaml_as :syck_yaml_as
end

class ActiveRecord::Base
  yaml_as "tag:ruby.yaml.org,2002:ActiveRecord"
end

module Syck
  class PrivateType
    def nil?
      return @type_id == "null"
    end
    alias old_blank? blank?
    def blank?
      return self.nil? || self.old_blank?
    end
  end
end
=end

Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 20
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 60.minutes
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.default_queue_name = 'default'


#reloading the model every time the worker is woken up
class Delayed::Worker
  alias :work_off_without_reload :work_off
  def work_off
    Rails.logger.debug "Clearing activerecord dependencies for delayed job"
    ActiveSupport::Dependencies.clear
    work_off_without_reload
  end
end

