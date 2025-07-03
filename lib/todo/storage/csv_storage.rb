class Todo
  module Storage
    class CsvStorage
      def initialize(path = 'tasks.csv')
        @path = path
      end

      def read
        tasks = []

        CSV.foreach @path, headers: true, header_converters: :symbol do |row|
          task = row.to_h
          task[:done] = task[:done] == 'true' if task.key? :done
          tasks << task
        end

        tasks
      rescue Errno::ENOENT => e
        raise TodoFileReadError.new("File not found: #{e.message}")
      rescue Errno::EACCES => e
        raise TodoFileReadError.new("Permission denied for reading: #{e.message}")
      rescue CSV::MalformedCSVError => e
        raise TodoFileReadError.new("Malformed CSV file: #{e.message}")
      rescue StandardError => e
        raise TodoFileReadError.new("Unexpected read error: #{e.message}")
      end

      def write(tasks)
        headers = tasks.first.keys # we use the keys as the headers

        CSV.open @path, 'w', write_headers: true, headers: headers do |csv|
          tasks.each do |task|
            csv << headers.map { |header| task[header] }
          end
        end
      rescue Errno::EACCES => e
        raise TodoFileWriteError.new("Permission denied for writing: #{e.message}")
      rescue Errno::ENOSPC => e
        raise TodoFileWriteError.new("No space left on device: #{e.message}")
      rescue Errno::EROFS => e
        raise TodoFileWriteError.new("Read-only file system: #{e.message}")
      rescue StandardError => e
        raise TodoFileWriteError.new("Unexpected write error: #{e.message}")
      end
    end
  end
end
