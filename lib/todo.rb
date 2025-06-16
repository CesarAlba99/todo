require 'json'
require 'securerandom'
require 'csv'

class Storage
  def read
    raise NotImplementedError, 'Subclasses must implement read method'
  end

  def write
    raise NotImplementedError, 'Subclasses must implement write method'
  end
end

class TodoError < StandardError
end

class TodoFileReadError < TodoError
end

class TodoFileWriteError < TodoError
end

class JsonStorage < Storage
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
  JSON.dump tasks, File.open(@path,'w')
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

class MemoryStorage < Storage
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

class CsvStorage < Storage
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

class Todo
  def initialize(storage)
    @storage = storage
  end

  def list_tasks
    @storage.read
  end

  def find_task(id)
    list_tasks.find { |task| task[:id] == id }
  end

  def delete_task(id)
    tasks = list_tasks
    task_to_delete = find_task id

    return if task_to_delete.nil?

    tasks.delete task_to_delete
    @storage.write tasks

    task_to_delete
  end

  def create_task(title, **attributes)
    raise 'title is required to create a task' if !title.is_a?(String) || title.empty?

    tasks = list_tasks

    new_task = attributes.merge id: SecureRandom.uuid, title: title # this order in case the user send also de title

    tasks << new_task
    @storage.write tasks

    new_task
  end

  def edit_task(id, **attributes)
    tasks = list_tasks
    index_task_to_edit = tasks.find_index { |task| task[:id] == id }

    return if index_task_to_edit.nil?

    tasks[index_task_to_edit].merge! attributes.merge(id: id)
    @storage.write tasks

    tasks[index_task_to_edit]
  end
end
