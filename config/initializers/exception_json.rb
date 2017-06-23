class Exception
  def as_json *args
    return {
      error: self.message,
      error_code: error_code
    }
  end
  def error_code
    return self.class.name
  end
end
