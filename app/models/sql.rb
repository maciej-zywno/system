class SQL

  def self.select_all(sql, params = {})
    sql = set_params(sql, params)
    ActiveRecord::Base.connection.select_all sql
  end

  private

    def self.set_param(sql, key, value)
      key = ['<', key.to_s, '>'].join
      sql.gsub key, value.to_s
    end

    def self.set_params(sql, hash)
      hash.each { |k, v| sql = set_param(sql, k, v) }
      sql
    end

end
