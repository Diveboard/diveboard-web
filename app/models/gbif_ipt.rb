class GbifIpt < ActiveRecord::Base


  belongs_to :dive

  def upd_attr attr,val
    return if attr == "" || attr.nil?
    write_attribute(attr.to_sym, val)
  end


  def exists?
    return false if self.dive.nil?
    return true if self.dive.species_sci_ids.include? self.eol_id
    return false
  end
end
