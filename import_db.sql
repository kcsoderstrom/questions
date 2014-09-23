CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  follower_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (follower_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  subject_question_id INTEGER NOT NULL,
  parent_reply INTEGER,
  reply_author_id INTEGER NOT NULL,
  body VARCHAR(255) NOT NULL,

  FOREIGN KEY (subject_question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id),
  FOREIGN KEY (reply_author_id) REFERENCES users(id)
);

INSERT INTO
  users(id, fname, lname)
VALUES
  (1, 'KC', 'Soderstrom'), (2, 'Kevin', 'Fleischman');

INSERT INTO
  questions(id, title, body, author_id)
VALUES
  (1, 'omg', 'I cant even', 1),
  (2, 'huh', 'what even is this', 2),
  (3, 'has anyone ever been so far', 'as to go want to do look more like', 1),
  (4, 'huh', 'do it be like it is?', 2);

INSERT INTO
  question_followers(id, follower_id, question_id)
VALUES
  (1, 1, 4), (2, 2, 2), (3, 2, 1);

INSERT INTO
  replies(id, subject_question_id, reply_author_id, body)
                                              -- check if can default arguments
VALUES
  (1, 2, 2, 'where IS EVERYONE'), (2, 4, 1, 'DO IT???');

INSERT INTO
  question_likes(id, question_id, user_id)
VALUES
  (1, 4, 1), (2, 1, 2), (3, 2, 2), (4, 3, 2);

