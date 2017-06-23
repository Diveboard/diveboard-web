module ActiveRecord
  class Relation
    def pluck_all(*args)
      args.map! do |column_name|
        if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
          "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
        elsif column_name.is_a? Hash
          column_name.map do |k,v|
            if v.is_a?(Symbol) && column_names.include?(v.to_s) then
              "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)} as #{connection.quote_column_name(k)}"
            else
              "#{v} AS #{k}"
            end
          end
        else
          column_name.to_s
        end
      end

      relation = clone
      relation.select_values = args.flatten
      returned_class=nil
      klass.connection.select_all(relation.arel).map do |attributes|
        initialized_attributes = klass.initialize_attributes(attributes)
        obj = HashWithFunctions.new
        attributes.each do |key, attribute|
          obj[key] = klass.type_cast_attribute(key, initialized_attributes)
        end
        obj
      end
    end
  end
end
