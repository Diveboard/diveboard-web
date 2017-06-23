class AreaCategory < ActiveRecord::Base
  belongs_to :area
  attr_accessible :areas, :category, :count
end
