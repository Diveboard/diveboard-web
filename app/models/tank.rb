class Tank < ActiveRecord::Base
  extend FormatApi

  belongs_to :dive
  validates_inclusion_of :material, :in => %w(aluminium steel carbon) # can't be nil
  validates_inclusion_of :gas, :in => %w(air EANx32 EANx36 EANx40 custom) # can't be nil
  validates :dive_id, :presence => true
  default_scope order("tanks.order asc")
  before_save :fill_gas_details

  define_format_api :public => [:dive_id, :gas, :gas_type, :he, :id, :material, :multitank, :n2, :o2, :order,
    :p_end, :p_end_value, :p_end_unit,  :p_start, :p_start_value, :p_start_unit, :time_start, :volume, :volume_unit, :volume_value]
  define_api_updatable_attributes %w( dive_id gas gas_type he id material multitank n2 o2 order p_end p_end_unit p_end_value p_start p_start_unit p_start_value time_start volume volume_unit volume_value)

  def is_private_for?(options={})
    return true if options[:caller].id == dive.user_id rescue nil
    return true if dive.user.is_private_for?(options) rescue false
    return false
  end

  def tankprofile
    #average depth & bottom time
    #average depth comes in SI
    begin
      if self.dive.tanks.count == 1
        ##only one tank
        avdepth = self.dive.avg_depth(nil, nil) ||(self.dive.maxdepth*2/3).to_f
        btime = self.dive.duration #in minutes
      else
        ##need to find actual depth and actual duration of the tank
        tanks = self.dive.tanks
        current_idx=0
        tanks.each_with_index do |t,i|
          if t.id == self.id then current_idx = i end
        end
        stime = time_start/60
        if current_idx == tanks.count - 1 then
          etime = self.dive.duration
        else
          etime = tanks[current_idx+1].time_start/60
        end
        btime = etime - stime
        avdepth = self.dive.avg_depth( stime*60,etime*60)
      end
      return {:average_depth => avdepth, :bottom_time => btime}
    rescue
      return {}
    end
  end

  def SAC_n (si=true)

    #http://www.scubaboard.com/forums/archive/index.php/t-338171.html
    #10L tank = 80 cu ft tank (when filled to 226.5 bar / 3285 psi)
    #12L tank = 100 cu ft tank (when filled to 236 bar / 3420 psi)
    #15L tank = 125 cu ft tank (when filled to 236 bar / 3420 psi)
    #18L tank = 150 cu ft tank (when filled to 236 bar / 3420 psi)
    #please note these calculations are using Australian conversions where 1 ata = 1 bar = 14.5 psi and 1 cu ft = 28.32 Litres

    begin
      ##init variables
      vol= multitank* volume_n(si)

      #pressure diff
      p_diff_n = p_start_n(si) - p_end_n(si)

      t = tankprofile
      ##do the maths
      mySAC = (p_diff_n / t[:bottom_time]) / ((t[:average_depth] / 10) + 1)
      if mySAC!=0 && (dive.uploaded_profile.source=="computer" || dive.uploaded_profile.source=="file")
        return round(mySAC, 2)
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def RMV_n (si=true)
    begin
      vol= multitank * volume_n(si)
      if si
        myRMV = SAC_n(si) * vol
      else
        myRMV = SAC_n(si) * (vol / pressure_rating(si))
      end
      return round(myRMV,3)
    rescue
      return nil
    end
  end

  def pressure_rating (si=true)
    if si
      return 236 #236 bars
    else
      return 3420 #3420 psis
    end
  end

  def round f, d
    (f * 10**d).round.to_f / 10**d
  end

  def p_start?
    if !p_start.nil? && p_start.round!=0
      return true
    else
      return false
    end
  end

  def p_start_n (si=true)
    #in @user's units
    begin
      if si
        round(p_start(0),2)
      else
        round(p_start(1),0)
      end
    rescue
      0
    end
  end

  def p_end?
    if !p_end.nil? && p_end.round !=0
      return true
    else
      return false
    end
  end

  def p_end_n (si=true)
    begin
      if si
        round(p_end(0),2)
      else
        round(p_end(1),0)
      end
    rescue
      0
    end
  end

  def volume_n (si=true)
    begin
      if si
        round(volume(0),2)
      else
        round(volume(1),2)
      end
    rescue
      0
    end
  end

  def time_start?
    if !time_start.nil? && time_start.round !=0
      return true
    else
      return false
    end
  end

  def time_m
    #time in minutes
    begin
      (self.time_start/60).to_i
    rescue
      0
    end
  end

  def he?
    if !he.nil? && he.round !=0
      return true
    else
      return false
    end
  end
  def o2?
    if !o2.nil? && o2.round !=0
      return true
    else
      return false
    end
  end
  def n2?
    if !n2.nil? && n2.round !=0
      return true
    else
      return false
    end
  end



  def p_start=(val)
    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        val = JSON.parse(val)
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      if self.dive.nil? || (!self.dive.nil? &&  !self.dive.user.nil? && self.dive.user.unitSI?)
        write_attribute(:p_start_unit, "bar")
        write_attribute(:p_start_value, val)
      else
        write_attribute(:p_start_unit, "psi")
        write_attribute(:p_start_value, DBUnit.convert(val, "bar", "psi"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:p_start_unit, val["unit"])
      write_attribute(:p_start_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:p_start_unit, nil)
      write_attribute(:p_start_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def p_start unit=0
    if unit == 0
      #SI (default)
      return DBUnit.convert(p_start_value, p_start_unit || "bar", "bar")
    else
      #IMPERIAL
      return DBUnit.convert(p_start_value, p_start_unit || "bar", "psi")
    end
  end

  def p_start_unit=(val)
    if val.match(/^bar$/i)
      write_attribute(:p_start_unit, "bar")
    elsif val.match(/^psi$/i)
      write_attribute(:p_start_unit, "psi")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable p_start_unit", val: val
    end
  end

  def p_end=(val)

    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        val = JSON.parse(val)
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"
      if self.dive.nil? || ( !self.dive.nil? &&  !self.dive.user.nil? && self.dive.user.unitSI?)
        write_attribute(:p_end_unit, "bar")
        write_attribute(:p_end_value, val)
      else
        write_attribute(:p_end_unit, "psi")
        write_attribute(:p_end_value, DBUnit.convert(val, "bar", "psi"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:p_end_unit, val["unit"])
      write_attribute(:p_end_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:p_end_unit, nil)
      write_attribute(:p_end_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def p_end unit=0
    if unit == 0
      #SI (default)
      return DBUnit.convert(p_end_value, p_end_unit || "bar", "bar")
    else
      #IMPERIAL
      return DBUnit.convert(p_end_value, p_end_unit || "bar", "psi")
    end
  end

  def p_end_unit=(val)
    if val.match(/^bar$/i)
      write_attribute(:p_end_unit, "bar")
    elsif val.match(/^psi$/i)
      write_attribute(:p_end_unit, "psi")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable p_end_unit", val: val
    end
  end


  def volume=(val)
    val = nil if val == ""

    if val.class.to_s == "String"
      if val.match(/^[-+]?[0-9]*\.?[0-9]+$/)
        val = val.to_f
      else
        val = JSON.parse(val)
      end
    end

    if val.class.to_s == "Fixnum" || val.class.to_s == "Float"

      if self.dive.nil? || ( !self.dive.nil? &&  !self.dive.user.nil? && self.dive.user.unitSI?)
        write_attribute(:volume_unit, "L")
        write_attribute(:volume_value, val)
      else
        write_attribute(:volume_unit, "cuft")
        write_attribute(:volume_value, DBUnit.convert(val, "L", "cuft"))
      end
    elsif val.class.to_s == "Hash"
      write_attribute(:volume_unit, val["unit"])
      write_attribute(:volume_value, val["value"].to_f)
    elsif val.nil?
      write_attribute(:volume_unit, nil)
      write_attribute(:volume_value, nil)
    else
      raise DBArgumentError.new "Could not understand value"
    end
  end

  def volume unit=0
    if unit == 0
      #SI (default)
      return DBUnit.convert(volume_value, volume_unit || "L", "L")
    else
      #IMPERIAL
      return DBUnit.convert(volume_value, volume_unit || "L", "cuft")
    end
  end

  def volume_unit=(val)
    if val.match(/^L$/i)
      write_attribute(:volume_unit, "L")
    elsif val.match(/^cuft$/i)
      write_attribute(:volume_unit, "cuft")
    else
      raise DBArgumentError.new "Provided unit is not an acceptable p_end_unit", val: val
    end
  end

  def pct_o2
    return o2.to_f/100.0 if gas == 'custom'
    return 0.21 if gas == 'air'
    return 0.32 if gas == 'EANx32'
    return 0.36 if gas == 'EANx36'
    return 0.40 if gas == 'EANx40'
  end

  def pct_n2
    return n2.to_f/100.0 if gas == 'custom'
    return 0.79 if gas == 'air'
    return 0.68 if gas == 'EANx32'
    return 0.64 if gas == 'EANx36'
    return 0.60 if gas == 'EANx40'
  end

  def pct_he
    return he.to_f/100 if gas == 'custom'
    return 0.0
  end

  def gas
    return nil if gas_type.nil?
    return 'air' if gas_type == 'air'
    return 'custom'
  end

  def gas=val
    if val.nil? then
      self.gas_type = nil
    elsif val == 'air' then
      self.gas_type = 'air'
    elsif val.match /EANx/ then
      self.gas_type = 'nitrox'
    else
      self.gas_type = 'trimix'
    end
  end

  def gas_name
    return 'Air' if gas_type == 'air'
    return "Nitrox #{(pct_o2*100).to_i}" if gas_type == 'nitrox'
    return "Trimix #{(pct_o2*100).to_i}/#{(pct_he*100).to_i}" if gas_type == 'trimix'
  end

  def gas_tag
    return 'Air' if gas_type == 'air'
    return "Nx #{(pct_o2*100).to_i}" if gas_type == 'nitrox'
    return "Tx #{(pct_o2*100).to_i}/#{(pct_he*100).to_i}" if gas_type == 'trimix'
  end

  def fill_gas_details
    begin
      if o2 == 21 && (he == 0 || he.nil?) then 
        self.gas_type = 'air' 
      elsif o2 > 21 && (he == 0 || he.nil?) then 
        self.gas_type = 'nitrox'
      elsif he != nil && he != 0 then 
        self.gas_type = 'trimix'
      end
    rescue
      gas = 'air'
    end
    
    if gas == 'air'
      o2 = 21
      n2 = 79
      he = 0
    elsif gas == 'EANx32'
      o2 = 32
      n2 = 68
      he = 0
    elsif gas == 'EANx36'
      o2 = 36
      n2 = 64
      he = 0
    elsif gas == 'EANx40'
      o2 = 40
      n2 = 60
      he = 0
    elsif gas_type == 'air'
      o2 = 21
      n2 = 79
      he = 0
    elsif gas_type == 'nitrox'
      he = 0
    end
    
  end

end
