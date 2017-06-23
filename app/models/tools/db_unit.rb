class DBUnit

  CONVERTIONS = {
    # DISTANCES
    "m > ft" => lambda {|x| x*3937/1200},
    "m > in"  => lambda {|x| x*12*3937/1200},
    "ft > m" => lambda {|x| x*1200/3937},
    "in > m"  => lambda {|x| x*1200/3937/12},
    "ft > in" => lambda {|x| x*12},
    "in > ft" => lambda {|x| x/12},
    # TEMPERATURES
    "C > F"  => lambda {|x| (x * 9 / 5) + 32},
    "F > C"  => lambda {|x| (x - 32) * 5 / 9},
    # PRESSURES
    "bar > psi"  => lambda {|x| x * 14.5038},
    "psi > bar"  => lambda {|x| x / 14.5038},
    # WEIGHT
    "kg > lbs"  => lambda {|x| x / 0.45359237},
    "lbs > kg"  => lambda {|x| x * 0.45359237},
    # VOLUMES
    "cuft > L"  => lambda {|x| x * ((381/1250.to_f)**3) * 1000 / 236},
    "L > cuft"  => lambda {|x| x * 236 / ((381/1250.to_f)**3) / 1000}
  }

  HANDLED_UNIT = {
    distance: ["m", "ft", "in"],
    temperature: ["C", "F"],
    pressure: ["bar", "psi"],
    weight: ["kg", "lbs"],
    volume: ["L", "cuft"],
  }

  def self.convert(val, unit_origin, unit_dest, rounding = nil)
    return nil if val.nil?
    return val if unit_origin == unit_dest
    begin
      r = CONVERTIONS["#{unit_origin} > #{unit_dest}"].call(val.to_f).to_f
    rescue NoMethodError => e
      raise DBArgumentError.new "Units are not convertible", from: unit_origin, to: unit_dest
    end
    return r if rounding.nil?
    return r.round(rounding)
  end

  def self.check_distance(unit)
    HANDLED_UNIT[:distance].include?(unit.to_s)
  end

  def self.check_temperature(unit)
    HANDLED_UNIT[:temperature].include?(unit.to_s)
  end

  def self.check_pressure(unit)
    HANDLED_UNIT[:pressure].include?(unit.to_s)
  end

  def self.check_weight(unit)
    HANDLED_UNIT[:weight].include?(unit.to_s)
  end

  def self.check_volume(unit)
    HANDLED_UNIT[:volume].include?(unit.to_s)
  end

end