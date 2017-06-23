class HashWithFunctions
  def initialize
    @h={}
  end
  def [] k
    @h[k.to_sym]
  end
  def []= k, val
    @h[k.to_sym] = val
  end
  def method_missing(m, *args, &block)
    self[m.to_sym]
  end
  def to_api *args
    @h.as_json
  end
  def as_json
    @h.as_json
  end
  def each &block
    @h.each &block
  end
  def map &block
    @h.map &block
  end
end