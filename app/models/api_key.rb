class ApiKey < ActiveRecord::Base
  belongs_to :user

  def self.validate key
    begin
      return !ApiKey.find_by_key(key).blank?
    rescue
      return false
    end
  end

end
