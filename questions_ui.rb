# Display information in a table.
# List all questions on left, authors on right
require_relative 'cursor_screen'
require_relative 'cursor'
require_relative 'plane_like'
require 'colorize'


class DisplayTable
  include CursorScreen
  include PlaneLike

  attr_accessor :cursor, :rows

  def initialize
    populate_rows
    @cursor = Cursor.new(2, @rows.count)
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
      select(self[cursor.pos])
    end
  end

end

class TopicsTable < DisplayTable

  def populate_rows
    results = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.id AS question_id, users.id AS author_id
    FROM
      questions JOIN users ON author_id=users.id
    SQL
    @rows = results.map do |data|
      [Question.find_by_id(data['question_id']),
        User.find_by_id(data['author_id'])] # do this with queries
    end
  end

  def render
    str = "Title".ljust(30) << "Author\n"
    @rows.each_with_index do |row, y|
      question_title = row[0].title
      author = row[1].fname + ' ' + row[1].lname
      if cursor.row == y
        if cursor.col == 0
          str << question_title.truncate.ljust(30).colorize(background: :white)
          str << author << "\n"
        else
          str << question_title.truncate.ljust(30)
          str << author.colorize(background: :white) << "\n"
        end
      else
        str << question_title.truncate.ljust(30) << author << "\n"
      end
    end
    str
  end

  def select(question)
    RepliesTable.new(question).run
  end

end

class RepliesTable < DisplayTable

  attr_accessor :question

  def initialize(question)
    @question = question
    super()
  end

  def populate_rows
    results = QuestionsDatabase.instance.execute(<<-SQL, @question.id)
    SELECT
      replies.id AS reply_id,
      reply_authors.id AS reply_author_id
    FROM
      questions
      JOIN
        replies
        ON subject_question_id=questions.id
      JOIN
        users AS reply_authors
        ON reply_author_id = reply_authors.id
    WHERE
      questions.id = (?)
    SQL
    results
    @rows = results.map do |data|
      [Reply.find_by_id(data['reply_id']),    # do this with queries
        User.find_by_id(data['reply_author_id'])]
    end
  end

  def render
    author = User.find_by_id(@question.author_id)

    str = question.title.colorize(:mode => :bold) << ' ' << "by "
    str << author.fname << ' ' << author.lname
    str << "\n"
    str << question.body
    str << "\n\n"

    str << "Reply".ljust(30) << "Author\n"
    @rows.each_with_index do |row, y|
      question_title = row[0].body
      author = row[1].fname + ' ' + row[1].lname
      if cursor.row == y
        if cursor.col == 0
          str << question_title.truncate.ljust(30).colorize(background: :white)
          str << author << "\n"
        else
          str << question_title.truncate.ljust(30)
          str << author.colorize(background: :white) << "\n"
        end
      else
        str << question_title.truncate.ljust(30) << author << "\n"
      end
    end
    str << "\n"
    str << "Likes: " << question.num_likes.to_s;
    str
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
