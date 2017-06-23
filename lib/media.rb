class Media < ActiveRecord::Base
  def self.select_all_sanitized(sql, hash={})
      sql = self.send(:sanitize_sql_array, [sql, hash])
      self.connection.select_all(sql)
  end
  def self.select_values_sanitized(sql, hash={})
      sql = self.send(:sanitize_sql_array, [sql, hash])
      self.connection.select_values(sql)
  end
  def self.select_value_sanitized(sql, hash={})
      sql = self.send(:sanitize_sql_array, [sql, hash])
      self.connection.select_value(sql)
  end
  def self.execute_sanitized(sql, hash={})
      sql = self.send(:sanitize_sql_array, [sql, hash])
      self.connection.execute(sql)
  end

  def self.insert_bulk_sanitized(table_name, values)
    keys = {}
    values.each do |val|
      val.keys.each do |k|
        keys[k] = true
      end
    end
    keys = keys.keys
    return if keys.length == 0
    sql_ids = keys.map do |k| ":#{k}" end .join ","
    sql_ids_insert = keys.map do |k| "`#{k}`" end .join ","
    sql_values = []
    values.each do |val|
      str = self.send(:sanitize_sql_array, [sql_ids, val])
      sql_values.push "(#{str})"
    end

    sql = "INSERT INTO #{table_name} (#{sql_ids_insert}) VALUES #{sql_values.join ','}"
    self.connection.insert(sql)
  end
end