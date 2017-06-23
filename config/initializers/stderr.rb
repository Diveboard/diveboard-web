

class IO
  alias old_puts puts
  def puts(*vals)
    if self.fileno == 2 then
      vals.each do |val|
        Rails.logger.info "STDERR: #{val}"
      end
    else
      old_puts(vals)
    end
  end
end

