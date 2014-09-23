# Display information in a table.
# List all questions on left, authors on right

class DisplayTable
  def initialize
    populate_display_rows
  end

  def populate_display_rows
    results = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      title, fname, lname
    FROM
      questions JOIN users ON author_id=users.id
    SQL
    @rows = results.map do |question|
      [question['title'], question['fname'] + ' ' + question['lname']]
    end
  end

  def render
    str = "Title".ljust(30) << "Author\n"
    @rows.each do |row|
      str << row[0].truncate.ljust(30) << row[1] << "\n"
    end
    str
  end

  def display
    puts render
  end

end

class String
  def truncate(cutoff=25)
    if self.length > cutoff
      return self[0..cutoff] + '...'
    end
    self
  end
end
