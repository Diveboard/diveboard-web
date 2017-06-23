module LogbookHelper


  def time_round_unit(time_min)
    str = ""
    if time_min > 60*24 then
      d = (time_min/(60.0*24)).floor
      str += It.it("day", count: d, scope:[:units]) + " "
    end

    if time_min > 60 then
      m = ((time_min%(60*24))/(60.0)).floor
      str += It.it("hr", count: m, scope:[:units]) + " "
    end

    mn = ((time_min%(60))).floor
    str += It.it("min", count: mn, scope:[:units])
    return str
  end
end
