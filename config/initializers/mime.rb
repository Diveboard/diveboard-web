module Mime
  class Type
    class << self
      # Lookup, guesstimate if fail, the file extension
      # for a given mime string. For example:
      #
      # >> Mime::Type.file_extension_of 'text/rss+xml'
      # => "xml"
      def file_extension_of(mime_string)
        set = Mime::LOOKUP[mime_string]
        sym = set.instance_variable_get("@symbol") if set
        return sym.to_s if sym
        return $1 if mime_string =~ /(\w+)$/
      end
    end
  end
end

