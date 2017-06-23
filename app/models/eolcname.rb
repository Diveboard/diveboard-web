class Eolcname < ActiveRecord::Base
  belongs_to :eolsname
  has_and_belongs_to_many :dives,
                          :class_name => 'Dive',
                          :join_table => "dives_eolcnames",
                          :foreign_key => 'cname_id',
                          :association_foreign_key => 'dive_id',
                          :uniq => true

  has_and_belongs_to_many :pictures,
                          :join_table => 'pictures_eolcnames',
                          :association_foreign_key => 'picture_id',
                          :foreign_key => 'cname_id',
                          :uniq => true

  def to_hash
    hash = {}
    hash[:id] = "c-"+self.id.to_s
    hash[:sname] = self.eolsname.sname
    hash[:cname] = self.cname
    hash[:picture] = self.eolsname.picture_href
    hash[:url] = self.eolsname.url
    hash[:description]=""
    hash[:description]=self.eolsname.eol_description

    return hash
  end


  def permalink
    self.eolsname.permalink
  end
  def fullpermalink *options
    self.eolsname.fullpermalink *options
  end
end
