class OracleBase < ActiveRecord::Base
  def self.test_data?
    self.settings.adapter == "postgresql"
  end

  def self.fake?
    self.settings.fake
  end

  def self.stringify_ints!(results, additional_columns=[])
    columns = stringified_columns + additional_columns
    if results.respond_to?(:to_ary)
      results.to_ary.each { |row| stringify_row!(row, columns) }
    else
      stringify_row!(results, columns)
    end
  end

  def self.stringify_row!(row, columns)
    columns.each { |column| self.stringify_column!(row, column) }
    row
  end

  def self.stringify_column!(row, column, zero_padding = 0)
    if row && row[column]
      return if row[column].is_a?(String)
      row[column] = "%0#{zero_padding}d" % row[column].to_i
    end
  end

  def self.stringified_columns
    []
  end

  # Oracle has a limit of 1000 terms per expression, so whitelist predicates with more than 1000 entries must be
  # constructed in chunks joined with OR.
  def self.chunked_whitelist(column_name, terms=[])
    predicates = terms.each_slice(1000).map do |slice|
      "#{column_name} IN (#{slice.join ','})"
    end
    "(#{predicates.join ' OR '})"
  end

  def self.preprocess(sql)
    # If using Postgres to mock an Oracle database during test runs, a couple of syntax hacks are necessary.
    # TODO We should probably come up with some kind of fixture/mock setup to avoid having to depend on fake databases. 
    if self.test_data?
      # Oracle wants double quotes around column names; Postgres seems to want them only if there are lowercase characters or dashes involved.
      sql.gsub!(/"([A-Z_]+)"/, '\1')
      # Remove ROWNUM clauses.
      sql.gsub!(/(and|where)\s+rownum\s+[<=]+\s+\d+/mi, '')
    end
    sql
  end
end
