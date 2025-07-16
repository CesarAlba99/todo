class Todo
  class Repository
    DB_CONNECTION_URI = ENV.fetch(
      'DB_CONNECTION_URI',
      'postgres://username:password@localhost:5433/todo'
    )

    def initialize(uri = DB_CONNECTION_URI)
      @db = Sequel.connect uri
    end

    FIND_USER_BY_USERNAME = <<~SQL.freeze
      SELECT * FROM users
      WHERE username = :username
        AND deleted_at IS NULL
    SQL

    def find_user_by_username(username)
      record = @db.fetch(FIND_USER_BY_USERNAME, { username: username }).first
      return if record.nil?

      Todo::Entities::User.new record
    end

    CREATE_USER = <<~SQL.freeze
      INSERT INTO users (username)
      VALUES (:username)
      ON CONFLICT(username) DO UPDATE SET deleted_at = NULL
      RETURNING *
    SQL

    def create_user(username)
      record = @db.fetch(CREATE_USER, { username: username }).first
      return if record.nil?

      Todo::Entities::User.new record
    end

    LIST_TASKS_BY_USER_ID = <<~SQL.freeze
      SELECT * FROM tasks
      WHERE user_id = :user_id
            AND deleted_at IS NULL
    SQL

    def list_tasks_by_user_id(user_id)
      records = @db.fetch(LIST_TASKS_BY_USER_ID, { user_id: user_id }).all
      return [] if records.nil? || records.empty?

      records.map { |record| Entities::Task.new record }
    end

    FIND_TASK_BY_ID = <<~SQL.freeze
      SELECT * FROM tasks
      WHERE id = :id
            AND deleted_at IS NULL
    SQL
    def find_task_by_id(id)
      record = @db.fetch(FIND_TASK_BY_ID, { id: id }).first
      return if record.nil?

      Todo::Entities::Task.new record
    end

    DELETE_TASK_BY_ID = <<~SQL.freeze
      UPDATE tasks SET deleted_at = NOW()
                   WHERE id = :id
      RETURNING *;
    SQL
    def delete_task_by_id(id)
      record = @db.fetch(DELETE_TASK_BY_ID, { id: id }).first
      return if record.nil?

      Todo::Entities::Task.new record
    end

    CREATE_USER_TASK = <<~SQL.freeze
      INSERT INTO tasks (user_id,title,description,deadline,done)
      VALUES (:user_id,:title,:description,:deadline,:done)
      RETURNING *;
    SQL
    def create_user_task(new_task)
      record = @db.fetch(CREATE_USER_TASK, new_task).first

      return if record.nil?

      Todo::Entities::Task.new record
    end

    UPDATE_USER_TASK = <<~SQL.freeze
      UPDATE tasks SET title = :title, description = :description,deadline = :deadline, done = :done
      WHERE id = :id
      RETURNING *
    SQL

    def edit_user_task_by_id(task)
      record = @db.fetch(UPDATE_USER_TASK, task).first

      return if record.nil?

      Todo::Entities::Task.new record
    end

    private

    attr_reader :db
  end
end
