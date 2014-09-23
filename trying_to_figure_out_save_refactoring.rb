module Saveable
  def drop_id
    self.instance_variables.drop(1)
  end

  def column_strings
    drop_id.map {|col| col.to_s.delete('@') }
  end

  def instance_variable_values
    drop_id.map { |sym| instance_variable_get(sym) }
  end

  def save(table_name)
    col_strs = column_strings
    vals = instance_variable_values

    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *vals)
      INSERT INTO
        #{table_name}(#{col_strs.join(', ')})
      VALUES
        (#{ col_strs.map { |col| '(?)' }.join(', ') })
       SQL

       @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, *vals, id)
      UPDATE
        #{table_name}
      SET
        #{ col_strs.each { |str| str.append(' = (?)') }.join(', ') }
      WHERE
        id = (?)
      SQL
    end
    nil
  end
end