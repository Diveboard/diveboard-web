class Signature < ActiveRecord::Base

  ##   `id` int(11) NOT NULL AUTO_INCREMENT,
  ##   `dive_id` int(11) DEFAULT NULL,
  ##   `signby_type` varchar(255) DEFAULT NULL, << "Shop"
  ##   `signby_id` int(11) DEFAULT NULL, << shop_id
  ##   `signed_data` text, << data json max depth, date, duration
  ##   `request_date` datetime DEFAULT NULL, << when the user has asked the signature
  ##   `signed_date` datetime DEFAULT NULL, << when shop has signed
  ##   `rejected` tinyint(1) DEFAULT '0', << 1 if shop rejected the siganture
  ##   `created_at` datetime DEFAULT NULL, << usual
  ##   `updated_at` datetime DEFAULT NULL, << usual
  ##   `notified_at` datetime DEFAULT NULL, << when we sent email to shop to ask him to review this




  validates :dive_id, :presence => true
  validates :signby_type, :presence => true
  validates :signby_id, :presence => true

  belongs_to :dive
  belongs_to :signby, :polymorphic => true

  before_save :prevent_dupes


  def prevent_dupes
    s = Signature.where(:dive_id => self.dive_id).where(:signby_type => self.signby_type).where(:signby_id => self.signby_id)
    same_id = true
    s.each {|e| if e.id != self.id then same_id = false end}
    raise DBArgumentError.new "A similar request with a different id already exists", id:s.map(&:id).to_json unless same_id
  end

  def status
    if !signed_date.nil?
      return :signed
    elsif !rejected
      return :pending
    elsif rejected
      return :rejected
    end
  end

  def sign
    self.signed_date = Time.now
    self.signed_data =  {
      :dive_id => self.dive.id,
      :max_depth_m => self.dive.maxdepth.to_f,
      :date => self.dive.time_in,
      :duration => self.dive.duration
    }.to_json
    self.save
  end

  def reject
    self.rejected = true
    self.save!
  end

  def signed_data
    JSON.parse(read_attribute(:signed_data))
  end

end

