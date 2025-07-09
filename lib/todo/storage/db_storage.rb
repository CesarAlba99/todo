class Todo
  module Storage
    class DBStorage
      DB_CONNECTION_URI = ENV.fetch(
        'DB_CONNECTION_URI',
        'postgres://username:password@localhost:5433/todo'
      )
      attr_reader :db, :username, :user_id

      def initialize(username, uri = DB_CONNECTION_URI)
        @db = Sequel.connect uri
        @username = username
        @user_id = fetch_user_id
      end

      GET_USER_ID = <<~SQL.freeze
        SELECT Id FROM users WHERE username = :username
      SQL
      def fetch_user_id
        result = db.fetch(GET_USER_ID, { username: username }).first
        result[:id]
      end

      ALL_TASKS_QUERY = <<~SQL.freeze
        SELECT *
        FROM tasks
        WHERE deleted_at IS NULL
              AND user_id = :user_id;
      SQL
      def read
        db.fetch(ALL_TASKS_QUERY, { user_id: user_id }).all
      end

      DELETE_USERS_TASKS = <<~SQL.freeze
        DELETE FROM tasks WHERE user_id = :user_id
      SQL
      CREATE_USERS_TASKS = <<~SQL.freeze
        INSERT INTO tasks (user_id,title,description,done)
        VALUES (:user_id,:title,:description,:done);
      SQL
      def write(tasks)

        db.fetch(DELETE_USERS_TASKS, {user_id: user_id}).all

        tasks.map do |task|
          db.fetch(CREATE_USERS_TASKS,
             {user_id: user_id, title: task[:title],
              description: task[:description],
              done: task[:done]}
          ).all

        end
      end
    end
  end
end
