module ValidationHelper

  def ValidationHelper.vanity_url_checker vanity
    keywords = %w(api settings login logout about explore spots species admin help)

    ##this should not be checked here
    #raise DBArgumentError.new "Not available" unless User.find_by_vanity_url(vanity).nil?
    raise DBArgumentError.new "Cannot be empty" if vanity.blank?
    raise DBArgumentError.new "Unauthorized characters" unless vanity.match(/^[A-Za-z0-9\-\_\.]*$/)
    raise DBArgumentError.new "Must be at least 4 characters" unless vanity.match(/^[A-Za-z0-9\-\_\.]{4,}$/)
    raise DBArgumentError.new "Must be at least 1 regular character" unless vanity.match(/[A-Za-z0-9]/)
    raise DBArgumentError.new "Unauthorized keyword" if keywords.include? vanity
  end

  def ValidationHelper.check_email_format email
    #OK, it's overkill, but it is RFC2822 compliant
    raise DBArgumentError.new "Cannot be empty" if email.blank?
    raise DBArgumentError.new "Email format is not valid", email: email unless email.match(Regexp.new '^(?:[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f\\])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f\\])+)\\])$')
  end

  def ValidationHelper.validate_and_filter_parameters(p, format_o)

    Rails.logger.debug 'entering validate_and_filter_parameters'
    return p if format_o.nil?

    if format_o.class == String then
      format = {:class => format_o}
    elsif format_o.class != Hash
      raise DBArgumentError.new 'Second parameter need to be a hash', classname: format_o.class.name
    else
      format = format_o
    end

    # If :nil parameter is true, then we accept the nil value
    if format[:nil]  && p.nil? then
      return nil
    end

    # If :presence parameter is true, then we accept the nil value
    if !format[:presence].nil? && !format[:presence] && p.nil? then
      return nil
    end

    if !format[:convert_if_string].nil? && p.class == String then
      p = format[:convert_if_string].call p
    end

    if !format[:class].nil? && format[:class].class == Array then
      found_class=false
      format[:class].each do |t|
        found_class ||= p.kind_of? t
      end
      if !found_class then
        raise DBArgumentError.new  "Invalid class - not in list", obj: p.inspect, list: format[:class].inspect, presence: format[:presence]
      end
    elsif !format[:class].nil? && p.class != format[:class] then
      raise DBArgumentError.new "Invalid class - not expected", obj: p.inspect, list: format[:class].inspect, classname: p.class.to_s
    end

    #validation of possible values
    if !format[:in].nil? then
      if !format[:in].include?(p) then
        raise DBArgumentError.new "Invalid value not included in list", value: p.inspect, list: format[:in]
      end
    end

    # sub-validation for hash and arrays
    ret_arg = nil
    if !format[:sub].nil? then
      if p.class == Hash then
        ret_arg = {}
        format[:sub].each do |e, f|
          begin
            #logger.debug "filtering : #{e} in #{p.keys}"
            if p.has_key? e then
              key = e
            elsif format[:key_to_sym] && e.methods.include?(:to_s) && p.has_key?(e.to_s) then
              key = e.to_s
            elsif f.class == Hash && (f[:presence].nil? || f[:presence]) then
              raise DBArgumentError.new 'key does not exists'
            else
              next
            end
            new_key = key
            new_key = key.to_sym if format[:key_to_sym] && key.methods.include?(:to_sym)
            ret_arg[new_key] = validate_and_filter_parameters(p[key], f)
            #logger.debug "ret : #{ret_arg.inspect}"
          rescue DBException => err
            #exception TODO
            raise DBArgumentError.new "Exception caught", exception: err, item: e.inspect
          end
        end
      elsif p.class == Array then
        ret_arg = []
        p.each do |e|
          begin
            ret_arg.push validate_and_filter_parameters(e, format[:sub])
          rescue DBException => err
            raise DBArgumentError.new "Exception caught", exception: err, item: e.inspect
          end
        end
      else
        raise DBArgumentError.new "subvalidation is not available on class", classname: p.class.name
      end
    else
      ret_arg = p
    end

    return ret_arg

  end

end
