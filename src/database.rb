require 'sqlite3'

class Database
  @db = nil

  def self.get_db
    @db = SQLite3::Database.new 'database.db'
    row = @db.execute "SELECT name FROM sqlite_master WHERE type='table' AND name='user_ranks'"
    return @db if row.count > 0

    row = @db.execute 'CREATE TABLE `user_ranks` ( `user_id` INTEGER NOT NULL UNIQUE, `messages_count` INTEGER NOT NULL DEFAULT 0, `rank` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(`user_id`) )'
    @db
  end

  def self.get_or_create_user_rank_row user_id
    rows = @db.execute 'SELECT * FROM user_ranks WHERE user_id=?', user_id
    return rows[0] if rows.count > 0

    rows = @db.execute 'INSERT INTO  user_ranks(user_id) VALUES(?)', user_id
    return rows[0]
  end

  def self.get_user_rank_row user_id
    rows = @db.execute 'SELECT * FROM user_ranks WHERE user_id=?', user_id
    return rows[0] if rows.count > 0
  end

  def self.update_user(user_id, messages, rank)
    rows = @db.execute "UPDATE user_ranks SET messages_count=?, rank=? WHERE user_id = ?", messages, rank,  user_id
    get_user_rank_row user_id
  end

  def self.top_ranked_users(n)
    @db.execute 'SELECT * FROM  user_ranks ORDER BY rank DESC LIMIT = ?', n
  end
end
