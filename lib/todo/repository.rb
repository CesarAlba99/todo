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
    # LIST_TASKS_BY_USER_ID_WITH_FILTERS = <<~SQL.freeze
    #   SELECT * FROM tasks
    #     WHERE user_id = :user_id
    #       AND deleted_at IS NULL
    #       AND (:title IS NULL OR LOWER(title) LIKE LOWER(:title_pattern))
    #       AND (:done IS NULL OR done = :done)
    #       AND (:start_deadline IS NULL OR deadline >= :start_deadline)
    #       AND (:end_deadline IS NULL OR deadline < :end_deadline)
    #     ORDER BY created_at DESC
    # SQL
    #
    LIST_TASKS_BY_USER_ID = <<~SQL.freeze
      SELECT * FROM tasks
      WHERE user_id = :user_id
            AND deleted_at IS NULL
    SQL

    def list_tasks_by_user_id(user_id, filters = {})
      conditions = []

      title, done, start_deadline, end_deadline = filters.values_at(
        :title,
        :done,
        :start_deadline,
        :end_deadline
      )

      conditions << 'title LIKE :title' unless title.nil?
      conditions << 'done = :done' unless done.nil?

      if start_deadline && end_deadline
        conditions << 'deadline >= :start_deadline AND deadline < :end_deadline'
      elsif start_deadline
        conditions << 'deadline >= :start_deadline'
      elsif end_deadline
        conditions << 'deadline < :end_deadline'
      end

      query = LIST_TASKS_BY_USER_ID

      conditions.each do |condition|
        query = "#{query} AND #{condition}"
      end

      @db.fetch(query, filters.merge({ user_id: user_id })).all.map do |task|
        Todo::Entities::Task.new task
      end
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
      INSERT INTO tasks (user_id,title,description,deadline,done,project_id)
      VALUES (:user_id,:title,:description,:deadline,:done,:project_id)
      RETURNING *;
    SQL
    def create_user_task(new_task)
      record = @db.fetch(CREATE_USER_TASK, new_task).first

      return if record.nil?

      Todo::Entities::Task.new record
    end

    UPDATE_USER_TASK = <<~SQL.freeze
      UPDATE tasks SET title = :title, description = :description,deadline = :deadline, done = :done, project_id = :project_id
      WHERE id = :id
      RETURNING *
    SQL
    def edit_user_task_by_id(task)
      record = @db.fetch(UPDATE_USER_TASK, task).first

      return if record.nil?

      Todo::Entities::Task.new record
    end

    FIND_PROJECT_BY_NAME = <<~SQL.freeze
      SELECT * FROM projects
      WHERE name = :name#{" "}
        AND user_id = :user_id
        AND deleted_at IS NULL
    SQL
    def find_project_by_name(user_id, name)
      record = @db.fetch(FIND_PROJECT_BY_NAME, { user_id: user_id, name: name }).first
      return nil if record.nil?

      Todo::Entities::Project.new record
    end

    CREATE_PROJECT = <<~SQL.freeze
      INSERT INTO projects (user_id,name)
      VALUES (:user_id,:name)
      RETURNING *
    SQL
    def create_project(user_id, name)
      record = @db.fetch(CREATE_PROJECT, { user_id: user_id, name: name }).first
      return if record.nil?

      Todo::Entities::Project.new record
    end

    private

    attr_reader :db
  end
end
