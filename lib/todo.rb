require 'json'
require 'securerandom'

class Storage
  def read
    raise NotImplementedError, 'Subclasses must implement read method'
  end

  def write
    raise NotImplementedError, 'Subclasses must implement write method'
  end
end

class JsonStorage < Storage
  def initialize(path = 'tasks.json')
    @path = path
  end

  def read
    JSON.parse File.read(@path)
  end

  def write(tasks)
    File.write @path, JSON.pretty_generate(tasks)
  end
end

class MemoryStorage < Storage
  def initialize(path = 'tasks.json')
    @tasks = JSON.parse File.read(path)
  end

  def read
    @tasks
  end

  def write(tasks)
    @tasks = tasks
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
    list_tasks.find { |task| task['id'] == id }
  end

  def delete_task(id)
    tasks = list_tasks
    task_to_delete = find_task id

    return if task_to_delete.nil?

    tasks.delete task_to_delete
    @storage.write tasks

    task_to_delete
  end

  def add_task(title, description = nil)
    tasks = list_tasks

    new_task = {
      'id' => SecureRandom.uuid,
      'title' => title,
      'description' => description,
      'done' => false,
    }

    tasks << new_task
    @storage.write tasks

    new_task
  end

  def edit_task(id, title: nil, description: nil, done: nil)
    tasks = list_tasks
    index_task_to_edit = tasks.find_index { |task| task['id'] == id }

    return if index_task_to_edit.nil?

    tasks[index_task_to_edit]['title'] = title unless title.nil?
    tasks[index_task_to_edit]['description'] = description unless description.nil?
    tasks[index_task_to_edit]['done'] = done unless done.nil?

    @storage.write tasks

    tasks[index_task_to_edit]
  end
end
