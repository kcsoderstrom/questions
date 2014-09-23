require 'singleton'
require 'sqlite3'
require_relative 'saveable'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  include Saveable
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

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(self.id)
  end

  def average_karma
    result = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      ( CAST(COUNT(question_likes.id) AS FLOAT) /
        COUNT(DISTINCT(questions.id)) ) AS karma
    FROM
      questions LEFT OUTER JOIN question_likes
      ON questions.id = question_id
    WHERE
      author_id = (?)
    GROUP BY
      author_id
    SQL
    result[0]['karma']
  end

end

class Question
  include Saveable
  attr_accessor :id, :title, :body, :author_id

  def self.all_questions
    QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      title, fname, lname
    FROM
      questions JOIN users ON author_id=users.id
    SQL
  end

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

  def self.most_followed(n)
    QuestionFollowers.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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

  def followers
    QuestionFollower.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def render(question)
    "Title: #{question.title} \tAuthor: #{question.author.fname + ' ' + question.author.lname}\n\n
    #{question.body}\n"
  end

end

class QuestionFollower
  include Saveable
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
      users.*
    FROM
      question_followers JOIN users ON follower_id = users.id
    WHERE
      question_id = (?)
    SQL
    results.map { |result| User.new(result) }
  end

  def self.followed_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      question_followers
    JOIN questions ON questions.id = question_id
    WHERE
      follower_id = (?)
    SQL
    results.map { |result| Question.new(result) }
  end

  def self.most_followed_questions(n)
    result = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*, COUNT(*) AS followers
    FROM
      question_followers JOIN questions ON questions.id = question_id
    GROUP BY
      questions.id
    ORDER BY
      followers
    LIMIT (?);
    SQL
    result.map { |result| Question.new(result) }
  end

  def initialize(options = {})
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

end

class QuestionLike
  include Saveable
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

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      question_likes JOIN users ON user_id = user.id
    WHERE
      question_id = (?)
    SQL
    results.map { |result| User.new(result) }
  end

  def self.num_likes_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(question_id) num_likes
    FROM
      question_likes
    WHERE
      question_id = (?)
    GROUP BY
      question_id
    SQL
    results[0]['num_likes']
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      question_likes JOIN questions ON question_id = questions.id
    WHERE
      user_id = (?)
    SQL
    results.map { |result| Question.new(result) }
  end

  def self.most_liked_questions(n)
    result = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      question_likes JOIN questions ON question_id = questions.id
    GROUP BY
      question_id
    ORDER BY
      COUNT(*)
    LIMIT (?);

    SQL

    result.map { |result| Question.new(result) }
  end

  def initialize(options = {})
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

end

class Reply
  include Saveable
  attr_accessor :id, :subject_question_id, :parent_reply,
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
    @parent_reply = options['parent_reply']
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
    return [] if parent_reply.nil?
    Reply.find_by_id(self.parent_reply)
  end

  def child_replies
    Reply.find_by_parent_id(self.id)
  end

end

