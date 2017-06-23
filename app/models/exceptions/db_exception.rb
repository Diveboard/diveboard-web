class DBException < StandardError
  attr_reader :error_code, :attributes, :error_message

  def initialize code, vars={}
    if code.is_a? String then
      @error_code = code.parameterize.underscore.to_sym
    else
      @error_code = code
    end

    if vars.is_a? Hash then
      @attributes = vars
      msg = It.it @error_code, @attributes, :scope => [:diveboard_errors], :raise => true rescue nil
      super(msg||"#{code} - #{vars.inspect}")
    else
      @attributes = {}
      super(vars)
    end
  end

  def as_json *args
    return {
      error_code: @error_code,
      message: self.message
    }
  end

end
