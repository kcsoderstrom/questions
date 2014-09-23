require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  attr_accessor :id, :fname, :lname

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = (?)
    SQL
    self.new(results[0])
  end

  def self.find_by_name(fname, lname)
    results = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = (?) AND lname = (?)
    SQL
    self.new(results[0])
  end

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_reply_author_id(self.id)
  end

end

class Question
  attr_accessor :id, :title, :body, :author_id

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = (?)
    SQL
    self.new(results[0])
  end

  def self.find_by_author_id(author_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = (?)
    SQL
    results.map { |result| self.new(result) }
  end

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    User.find_by_id(self.author_id)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

end

class QuestionFollower
  attr_accessor :id, :follower_id, :question_id

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_followers
    WHERE
      id = (?)
    SQL
    self.new(results[0])
  end

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      follower_id
    FROM
      question_followers
    WHERE
      question_id = (?)
    SQL
    results
    #results.map { |result| User.find_by_id(result.value) }
  end

  def initialize(options = {})
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

end

class QuestionLike
  attr_accessor :id, :question_id, :user_id

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      id = (?)
    SQL
    self.new(results[0])
  end

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

end

class Reply
  attr_accessor :id, :subject_question_id, :parent_id,    # name no match
                :reply_author_id, :body

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = (?)
    SQL
    self.new(results[0])
  end

  def self.find_by_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = (?)
    SQL
    results.map { |result| self.new(result) }
  end

  def self.find_by_reply_author_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      reply_author_id = (?)
    SQL
    results.map { |result| self.new(result) }
  end

  def self.find_by_parent_id(parent_reply)
    results = QuestionsDatabase.instance.execute(<<-SQL, parent_reply)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_reply = (?)
    SQL
    results.map { |result| self.new(result) }
  end

  def initialize(options = {})
    @id = options['id']
    @subject_question_id = options['subject_question_id']
    @parent_id = options['parent_reply']        # names don't match WARNING!!
    @reply_author_id = options['reply_author_id']
    @body = options['body']
  end

  def author
    User.find_by_id(self.reply_author_id)
  end

  def question
    Question.find_by_id(self.subject_question_id)
  end

  def parent_reply
    return [] if parent_id.nil?
    Reply.find_by_id(self.parent_id) # may have to handle parent = nil
  end

  def child_replies
    Reply.find_by_parent_id(self.id)
  end

end

