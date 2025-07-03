class Todo
  module Storage
    class DBStorage
      DB_CONNECTION_URI = ENV.fetch(
        'DB_CONNECTION_URI',
        'postgres://username:password@localhost:5433/todo'
      )
      attr_reader :db, :username

      def initialize(username, uri = DB_CONNECTION_URI)
        @db = Sequel.connect uri
        @username = username
      end
      ALL_TASKS_QUERY = <<~SQL.freeze
        SELECT tasks.*
        FROM tasks
          JOIN users ON users.id = tasks.user_id
            AND users.deleted_at IS NULL
        WHERE tasks.deleted_at IS NULL#{" "}
            AND users.username = :username
      SQL
      def read
        db.fetch(ALL_TASKS_QUERY, { username: username })
      end

      DELETE_USERS_TASKS = <<~SQL.freeze
        DELETE FROM tasks
        USING users
        WHERE users.id = tasks.user_id
          AND users.username = :username
      SQL
      CREATE_USERS_TASKS = <<~SQL.freeze

      SQL

      # IMPLEMENTAR WRITE Y QUE LOS FILTROS SEAN POR USER_ID(O SEA OBTENERLO Y PASARLO)
      # ARREGLAR LOS SPECS(CORREGIR LOS REQUIRE CON LA NUEVA ORGANIZACIÓN)
      def write(tasks); end
    end
  end
end
