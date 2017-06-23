
class FormatApiCache
  include Singleton

  attr_accessor :cache_stack, :cache_api, :disable_cache

  def stack obj=nil, flavour=nil, &block
    return yield if @disable_cache
    @cache_stack ||= []
    @cache_api ||= {}

    key = "#{obj.class}##{obj.id}" rescue :unknown
    @cache_stack.push key

    @cache_api[flavour] ||= {}

    if key != :unknown && @cache_api[flavour].has_key?(key) then
      #puts "%-140s %s" % [ @cache_stack.join("   "), "!!! HIT !!! #{flavour}"]
      r = @cache_api[flavour][key]
    else
      #puts "%-140s %s" % [ @cache_stack.join("   "), "   MISS     #{flavour}"]
      r=yield(@cache_api)
      @cache_api[flavour][key] = r unless key==:unknown
    end

    @cache_stack.pop
    @cache_api = nil if @cache_stack.length <= 0
    r
  end
end

module FormatApi

  ## This should be seen as the initializer
  def self.extended(base)
    base.class_variable_set('@@format_api_includes', { :* => [:public] })
    base.class_variable_set('@@format_api_updatable_attributes', [])
    base.class_variable_set('@@format_api_updatable_attributes_rec', {})
    base.class_variable_set('@@format_api_requiring_id', [])
    base.class_variable_set('@@format_api_searchable_attributes', [])
    base.class_variable_set('@@format_api_check_end_state', false)

    base.send :define_method, :is_private_for? do |options={}|
      return true if options[:private]
      return false
    end

    base.send :define_method, :is_reachable_for? do |options={}|
      return true
    end
  end


  def define_format_api(flavours_definition)
    send :define_method, :to_api do |flavor, arg_options = {}|

      options = arg_options.dup
      options[:private] = false if options[:private].nil?

      ## This is the main function that evaluates all the attributes for one flavour
      extract_flavor = Proc.new { |flav|
        r = {:class => self.class.to_s }
        r[:flavour] = flav
        flavours_definition[flav].each do |a|
          if a.class == Symbol then
            r[a] = a.to_proc.call self
            ## calls to_api whenever possible on sub elements
            r[a] = r[a].to_api flavor, options if r[a].respond_to?(:to_api)
          elsif a.class == Hash then
            a.each do |k, v|
              if v.class == Symbol then
                r[k] = v.to_proc.call self
              elsif v.class == Proc && v.arity == 0 then
                r[k] = v.call self
              elsif v.class == Proc && v.arity == 1 then
                r[k] = v.call self
              elsif v.class == Proc && v.arity >= 2 then
                r[k] = v.call self, options
              else
                r[k] = v
              end
              ## calls to_api whenever possible on sub elements
              r[k] = r[k].to_api flavor, options if r[k].respond_to?(:to_api)
            end
          end
        end
        r
      }

      ## Let's decide which flavours need to be stacked based on @@format_api_includes
      applied_flavours = [flavor].flatten
      applied_flavours.reverse!
      todo = applied_flavours + [:*]
      includes = self.class.class_variable_get('@@format_api_includes') rescue {}
      while todo.length > 0 do
        new_todo = []
        todo.each do |t|
          new_todo += includes[t] if !includes[t].nil?
        end
        new_todo.uniq!
        todo = new_todo - applied_flavours
        applied_flavours += todo
      end

      # make sure the object is allowed
      return nil unless self.is_private_for?(options) || self.is_reachable_for?(options)

      ## Let's apply every needed flavor
      FormatApiCache.instance.stack(self, flavor) do |cache|
        r = {}
        applied_flavours.reverse.each do |f|
          r.merge!(extract_flavor.call(f)) unless flavours_definition[f].nil?
        end

        # Let's remove all private attributes unless stated otherwise
        is_private = self.is_private_for?(options)
        begin
          r.except! *self.class.class_variable_get('@@format_api_private_attributes') unless is_private
        rescue
        end

        # Same here but for conditional privacy
        conditions = self.class.class_variable_get('@@format_api_conditional_private_attributes') rescue []
        conditions && conditions.each do |condition|
          r.except! *(condition.call(self)) unless is_private || !condition.respond_to?(:call)
        end

        r
      end
    end
  end

  def define_api_includes(h)
    class_variable_set('@@format_api_includes', h)
  end

  def define_api_private_attributes *attrs
    class_variable_set('@@format_api_private_attributes', attrs)
  end

  def define_api_conditional_private_attributes *attrs
    class_variable_set('@@format_api_conditional_private_attributes', attrs)
  end

  def define_api_requiring_id(h)
    class_variable_set('@@format_api_requiring_id', h)
  end

  #def use_in_api(attribute, options = {})
  #  class_variable_set :@@format_api_protected, {} unless class_variables.include? :@@format_api_protected
  #  protection = class_variable_get(:@@format_api_protected)
  #  protection[attribute] = options.protected

  #  class_variable_set :@@format_api_flavors, {} unless class_variables.include? :@@format_api_flavors
  #  config = class_variable_get(:@@format_api_flavors)
  #  options.flavors.each do |flavor|
  #    config[flavor] = [] if config[flavor].nil?
  #    config[flavor].push attribute
  #  end
  #end

  def define_api_searchable_attributes list
    class_variable_set('@@format_api_searchable_attributes_direct', list.reject do |e| e.is_a? Hash end .map(&:to_sym))
    complex = {}
    list.each do |h|
      if h.is_a? Hash then
        h.each do |key, val|
          complex[key.to_sym] = val
        end
      end
    end
    class_variable_set('@@format_api_searchable_attributes_complex', complex)
  end

  def define_api_updatable_attributes list
    class_variable_set('@@format_api_updatable_attributes', list.map(&:to_s))
  end

  def define_api_updatable_attributes_rec list
    h = {}
    list.each do |k,v|
      h[k.to_s] = v
    end
    class_variable_set('@@format_api_updatable_attributes_rec', h)
  end

  def define_api_check_end_state(b)
    class_variable_set('@@format_api_check_end_state', b)
  end


  def create_or_update_from_api(h, options = {})
    begin
      errors = []
      local_options = options.dup
      if h.nil? then
        return {:error => errors, :target => nil}
      elsif h.is_a? Array then
        targets = []
        h.each do |elt|
          ret = self.create_or_update_from_api(elt, options)
          errors += ret[:error]
          targets.push ret[:target] unless !ret.include?(:target)
        end
        return { :error => errors, :target => targets }
      end

      #make sure everything is in strings
      args = {}
      h.each do |k,v|
        args[k.to_s] = v
      end

      ## First get the object we'll be working on
      target = nil
      if !args['id'].nil? then
        begin
          target = self.unscoped.find(args['id']) rescue raise(::DBArgumentError.new "Object does not exist", classname: self.name, id: args['id'])
          local_options[:action] = :update
          raise ::DBArgumentError.new "Object not accessible", classname: self.name, id: args['id'] if target.respond_to?(:is_accessible_for?) && !target.is_accessible_for?(local_options)
        rescue
          Rails.logger.debug $!.message
          errors.push($!.message)
          return { :error => errors}
        end
      else
        target = self.new
        local_options[:action] = :create
      end

      ## Check if the user is allowed for updates but only warn later if some update is attempted
      change_allowed = target.is_private_for?(local_options)

      #filters updatable attributes
      args = args.slice *(class_variable_get('@@format_api_updatable_attributes') + class_variable_get('@@format_api_updatable_attributes_rec').keys)

      array_args = []
      args.each do |a,v|
        array_args.push([a,v])
      end
      args = array_args

      #order args
      args.sort do |a, b|
        a_need_id = class_variable_get('@@format_api_requiring_id').include?(a[0]) rescue false
        b_need_id = class_variable_get('@@format_api_requiring_id').include?(b[0]) rescue false
        a_direct = class_variable_get('@@format_api_updatable_attributes').index(a[0])
        b_direct = class_variable_get('@@format_api_updatable_attributes').index(b[0])

        if a_need_id && !b_need_id then 1
        elsif !a_need_id && b_need_id then -1
        elsif a_direct && b_direct then (a_direct - b_direct>0)?1:-1
        elsif a_direct && !b_direct then -1
        elsif !a_direct && b_direct then 1
        else 1
        end
      end

      #Updates attributes
      args.each do |attr, val|
        begin
          begin
            current_val = target.send(attr)
          rescue NoMethodError
            current_val = nil
          end
          next if current_val == val
          raise ::DBArgumentError.new 'Forbidden' if !change_allowed
          #save if we need the object to have an id
          target.save! if class_variable_get('@@format_api_requiring_id').include?(attr) && target.id.nil?
          #if we fall on an assocation
          if class_variable_get('@@format_api_updatable_attributes_rec').include? attr then
            ret = {}
            if target.send(attr).respond_to? :create_or_update_from_api then
              ret = target.send(attr).create_or_update_from_api(val, options)
            else
              ret = class_variable_get('@@format_api_updatable_attributes_rec')[attr].create_or_update_from_api(val, options)
            end
            target.send "#{attr}=", ret[:target]
            errors += ret[:error]
          else
            target.send "#{attr}=", val
          end
          #we may have deleted elements so they need to be saved
          if current_val.respond_to? :each then
            current_val.each do |o|
              begin
                o.save! if o.changed?
              rescue
              end
            end
          end
        rescue DBException => e
          Rails.logger.debug "DBException caught within create_or_update_from_api : #{e}"
          Rails.logger.debug e.backtrace.join("\n")
          errors.push($!.as_json.merge({:attribute => attr, :object => h}))
        rescue
          msg = "Error while updating attribute '#{attr}' with '#{args[attr] rescue "?"}' on object #{target.class.name}(#{target.id}) : #{$!.message}"
          NotificationHelper.mail_background_exception $!, msg, "Requested change: #{h.inspect}", "Options: #{options.inspect}"
          Rails.logger.debug msg
          Rails.logger.debug $!.backtrace.join("\n")
          errors.push($!.as_json.merge({:attribute => attr, :object => h}))
        end
      end

      raise ::DBArgumentError.new 'End state forbidden' if class_variable_get('@@format_api_check_end_state') && !target.is_private_for?(local_options)

      target.touch if !target.changed? && args.count > 0
      target.save! if target.changed?

    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.each do |attr, message|
        msg = "Validation error for #{self.name} (#{$!.message})"
        errors.push $!.as_json.merge({:attribute => attr, :object => h})
      end
    rescue
      msg = "Error for #{self.name} (#{$!.message})"
      NotificationHelper.mail_background_exception $!, msg
      errors.push $!.as_json.merge({:object => h})
    end

    target.reload rescue nil
    return {:error => errors, :target => target} unless target.respond_to?(:new_record?) && target.new_record?
    errors.push ::DBArgumentError.new("Object cannot be saved").as_json.merge({:object => h})
    return {:error => errors}
  end


  def search_for_api initial_search_opts={}, flavour='public', initial_access_opts={}
    if initial_access_opts.is_a? Hash then
      access_opts = initial_access_opts.clone
    else
      access_opts = {}
    end

    if initial_search_opts.is_a? Hash then
      search_opts = initial_search_opts.clone
    else
      search_opts = {}
    end

    search_opts[:limit] = 20 if !search_opts[:limit] || search_opts[:limit] > 50
    search_opts[:start_id] ||= 0

    allowed_attrs_direct = class_variable_get('@@format_api_searchable_attributes_direct')
    allowed_attrs_complex = class_variable_get('@@format_api_searchable_attributes_complex')



    #Handle the "filter"
    if search_opts[:filter].is_a? Array then
      filter_list = search_opts[:filter]
    elsif search_opts[:filter].is_a? Hash then
      filter_list = [ search_opts[:filter] ]
    else
      filter_list = []
    end

    Rails.logger.debug filter_list.inspect

    private_attrs = self.class_variable_get('@@format_api_private_attributes') rescue []

    # Validating and constructing the where clause from the "filter"
    filtering_on_private_attrs = false
    additional_joins = []
    validated_filter_list = []
    filter_list.each do |filter|
      validated_attrs = {}
      filter.each do |key, value|
        if value.is_a? Array then
          filtered_value = value.map do |val|
            raise ::DBArgumentError.new "Invalid parameter", value: value, classname: value.class.name if ![Date, String, Fixnum, NilClass].include?(val.class)
            val
          end
        elsif [Date, String, Fixnum, NilClass].include?(value.class) then
          filtered_value = value
        else
          raise ::DBArgumentError.new "Invalid parameter", value: value, classname: value.class.name
        end
        if allowed_attrs_direct.include?(key.to_sym) then
          validated_attrs[key.to_sym] = filtered_value
          filtering_on_private_attrs ||= private_attrs.include?(key.to_sym)
        elsif allowed_attrs_complex[key.to_sym] then
          how = allowed_attrs_complex[key.to_sym]
          additional_joins.push how[:join]
          validated_attrs[how[:key]] = filtered_value
          filtering_on_private_attrs ||= private_attrs.include?(key.to_sym)
        end
      end
      validated_filter_list.push(validated_attrs) unless validated_attrs.blank?
    end

    Rails.logger.debug validated_filter_list.inspect

    #ActiveRecord doesn't natively support 'OR' within conditions....
    #So we need to use AREL stuff instead
    arel = nil
    validated_filter_list.each do |conditions|
      arel_and = nil
      self.where(conditions).where_values.each do |arel_where|
        if arel_and then
          arel_and = arel_and.and(arel_where)
        else
          arel_and = arel_where
        end
      end
      if arel then
        arel = arel.or(arel_and)
      else
        arel = arel_and
      end
    end


    #now let's prepare the order statement
    if search_opts[:order].is_a? Array then
      order_list = search_opts[:order]
    elsif search_opts[:order] then
      order_list = [ search_opts[:order] ]
    else
      order_list = []
    end

    filtered_order_list = []

    order_list.each do |att|
      matched = att.match(/^([a-zA-Z_]*) +(ASC|DESC)$/i) rescue nil
      if allowed_attrs_direct.include? att.to_sym then
        filtered_order_list.push att
      elsif matched && allowed_attrs_direct.include?(matched[1].to_sym) then
        filtered_order_list.push att
      elsif allowed_attrs_complex[att.to_sym] then
        how = allowed_attrs_complex[att.to_sym]
        filtered_order_list.push how[:key]
        additional_joins.push how[:join]
      elsif matched && allowed_attrs_complex[matched[1].to_sym] then
        how = allowed_attrs_complex[matched[1].to_sym]
        filtered_order_list.push "#{how[:key]} #{matched[2]}"
        additional_joins.push how[:join]
      end
    end

    Rails.logger.debug "Order: #{filtered_order_list.inspect}"

    #OK, we're ready to make the request...
    additional_joins.flatten!
    additional_joins.reject! &:nil?
    additional_joins.uniq!

    raise ::DBArgumentError.new "Too many answers for filter, please refine filter" if self.joins(additional_joins).where(arel).count > 2000


    # Loop until we found enough elements
    found_elements = []
    found_counter = 0
    current_offset = (search_opts[:start_id]/7).to_i rescue 0  ##Just some stupid obfuscation of start_id

    while true do
      current_set = self.joins(additional_joins).where(arel).order(filtered_order_list).limit(20).offset(current_offset).to_ary
      if current_set.count == 0 then
        return {
          :result => found_elements.to_api(flavour, access_opts),
          :count => found_counter,
          :next_start_id => nil
        }
      end

      current_set.each do |element|
        # We don't want to list element if not reachable or if we would give hints on private attributes
        if element.is_reachable_for?(access_opts) && (element.is_private_for?(access_opts) || !filtering_on_private_attrs) then
          if found_counter >= search_opts[:limit] then
            return {
              :result => found_elements.to_api(flavour, access_opts),
              :count => found_counter,
              :next_start_id => (7*current_offset+Random.new.rand(7))
            }
          else
            found_elements.push element
            found_counter += 1
          end
        end
        current_offset += 1
      end
    end
  end

end


class Array
  def to_api *args
    map {|a|
      if a.respond_to? :to_api then
        a.to_api *args
      else
        a.to_s
      end}
  end
end

class Hash
  def to_api *args
    h={}
    each {|a,b|
      if b.respond_to? :to_api then
        h[a] = b.to_api *args
      else
        h[a] = b.to_s
      end}
    h
  end
end

class Fixnum
  def to_api *args
    self
  end
end

class TrueClass
  def to_api *args
    self
  end
end

class FalseClass
  def to_api *args
    self
  end
end

class String
  def to_api *args
    self
  end
end

class Fixnum
  def to_api *args
    self
  end
end

class Float
  def to_api *args
    self
  end
end

class NilClass
  def to_api *args
    self
  end
end

