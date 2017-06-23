
def private_setters(*list)
    list.each do |attr|
      send :define_method, "#{attr.to_s}=" do |val|
        write_attribute(attr, val)
      end
      send :private, "#{attr.to_s}="
    end
end

def private_getters(*list)
    list.each do |attr|
      send :define_method, attr do |val|
        read_attribute(attr, val)
      end
      send :private, attr
    end
end

def private_attributes(*list)
  private_getters *list
  private_setters *list
end
