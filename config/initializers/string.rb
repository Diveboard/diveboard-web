class String
  SPACE = ' '
  APOS = "'"

  # Extension of the string class to properly handle camel names
  def nameize
    case self
    when / /
    # If the name has a space in it, we gotta run the parts through the nameizer.
    split(SPACE).each { |part| part.nameize! }.join(SPACE)
    when /^[A-Z]/
    # If they took the time to capitalize their name then let's just jump out.
    self
    when /^(mac|mc)(\w)(.*)$/i
    "#{$1.capitalize}#{$2.capitalize}#{$3}"
    when /^o\'/i
    split(APOS).each{ |piece| piece.capitalize! }.join(APOS)
    else
    capitalize # Basically if the name is a first name or it's not Irish then capitalize it.
    end
  end

  def nameize!
    replace nameize # BANG!
  end

end

