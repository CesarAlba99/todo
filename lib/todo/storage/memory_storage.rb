class Todo
  module Storage
    class MemoryStorage
      def initialize(tasks = [])
        @tasks ||= tasks
      end

      def read
        @tasks
      end

      def write(tasks)
        @tasks = tasks
      end
    end
  end
end
