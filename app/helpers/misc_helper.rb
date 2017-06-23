module MiscHelper
  def MiscHelper.nameize(text, options = {})
    text.split("-").map(&:nameize).join("-")
  end
end