# Display information in a table.
# List all questions on left, authors on right
require_relative 'cursor_screen'
require_relative 'cursor'
require 'colorize'


class DisplayTable
  include CursorScreen

  attr_accessor :cursor

  def initialize
    populate_display_rows
    @cursor = Cursor.new(2, @rows.count)
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
    @rows.each_with_index do |row, y|
      if cursor.row == y
        if cursor.col == 0
          str << row[0].truncate.ljust(30).colorize(background: :white)
          str << row[1] << "\n"
        else
          str << row[0].truncate.ljust(30)
          str << row[1].colorize(background: :white) << "\n"
        end
      else
        str << row[0].truncate.ljust(30) << row[1] << "\n"
      end
    end
    str
  end

  def display
    puts render
  end

  def run
    while true
      clear_screen
      self.display
      process_chr(get_chr)
    end
  end

  def process_chr(chr)
    unless chr == ' '
      cursor.scroll(chr.to_sym)
    else
      #select
    end
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
