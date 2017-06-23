class TrueClass
  def <=>(b)
    if b.class == TrueClass
      return 0
    elsif b.class == FalseClass
      return 1
    else
      return nil
    end
  end
end
class FalseClass
  def <=>(b)
    if b.class == FalseClass
      return 0
    elsif b.class == TrueClass
      return -1
    else
      return nil
    end
  end
end