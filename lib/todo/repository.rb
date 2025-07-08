class Todo
  class Repository
    DB_CONNECTION_URI = ENV.fetch(
      'DB_CONNECTION_URI',
      'postgres://username:password@localhost:5433/todo'
    )

    def initialize(username, uri = DB_CONNECTION_URI)
      @db = Sequel.connect uri
    end

    def find_user(id)
    end

    def create_user(user_properties)
    end

    def create_task(task_properties)
    end

    private

    attr_reader :db
  end
end
