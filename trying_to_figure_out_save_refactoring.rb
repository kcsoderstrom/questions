#TODO: @id comes last

  def save
    vars = self.instance_variables.drop(1).map {|var| var.to_s.delete('@') }
    if id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *vars)
      INSERT INTO
        question_followers(#{*vars})
      VALUES
        ((?), (?))
       SQL

       @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, follower_id, question_id, id)
      UPDATE
        question_followers
      SET
        follower_id = (?), question_id = (?)
      WHERE
        id = (?)
      SQL
    end
    nil
  end