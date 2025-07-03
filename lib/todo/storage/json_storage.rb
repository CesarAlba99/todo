class Todo
  module Storage
    class JsonStorage
      def initialize(path = 'tasks.json')
        @path = path
      end

      def read
        JSON.parse File.read(@path), { symbolize_names: true }
      rescue Errno::ENOENT => e
        raise TodoFileReadError.new("File not found: #{e.message}")
      rescue Errno::EACCES => e
        raise TodoFileReadError.new("Permission denied for reading: #{e.message}")
      rescue JSON::ParserError => e
        raise TodoFileReadError.new("JSON parsing error: #{e.message}")
      rescue StandardError => e
        raise TodoFileReadError.new("Unexpected read error: #{e.message}")
      end

      def write(tasks)
        JSON.dump tasks, File.open(@path, 'w')
      rescue Errno::ENOENT => e
        raise TodoFileWriteError.new("File or directory not found: #{e.message}")
      rescue Errno::EACCES => e
        raise TodoFileWriteError.new("Permission denied for writing: #{e.message}")
      rescue Errno::EROFS => e
        raise TodoFileWriteError.new("Read-only file system: #{e.message}")
      rescue StandardError => e
        raise TodoFileWriteError.new("Unexpected write error: #{e.message}")
      end
    end
  end
end
