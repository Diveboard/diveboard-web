class Domain
  def self.matches?(request)
    request.domain.present? && request.domain == "scu.bz"
  end
end