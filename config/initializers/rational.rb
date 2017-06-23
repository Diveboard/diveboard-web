class Rational
  def as_json(options={})
    self.to_s
  end
end
