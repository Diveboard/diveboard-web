class GeonamesAlternateName < ActiveRecord::Base

  belongs_to :geonames_core, :foreign_key => :geoname_id

end
