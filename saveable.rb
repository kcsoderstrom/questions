require 'active_support/inflector'

module Saveable
  def drop_id
    vars = self.instance_variables
    vars.delete(:@id)
    vars
  end

  def column_strings
    drop_id.map {|col| col.to_s.delete('@') }
  end

  def instance_variable_values
    drop_id.map { |sym| instance_variable_get(sym) }
  end

  def save
    col_strs = column_strings
    vals = instance_variable_values

    if id.nil?
      create
    else
      update
    end
    nil
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, *instance_variable_values)
      INSERT INTO
        #{table_name}(#{column_strings.join(', ')})
      VALUES
        #{ sql_values_string }
       SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, *instance_variable_values, id)
    UPDATE
      #{ table_name }
    SET
      #{ sql_set_string }
    WHERE
      id = (?)
    SQL
  end

  def sql_set_string
    column_strings.each { |str| str.append(' = (?)') }.join(', ')
  end

  def sql_values_string
    "(#{column_strings.map { |col| '?' }.join(', ')})"
  end

  def table_name
    self.class.to_s.tableize
  end

end