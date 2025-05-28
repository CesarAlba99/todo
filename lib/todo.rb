require 'json'
require 'securerandom'

module TaskFile
  def list_tasks
    raise NotImplementedError, 'Must implement list_tasks'
  end

  def find_task(id)
    raise NotImplementedError, 'Must implement find_task'
  end

  def delete_task(id)
    raise NotImplementedError, 'Must implement delete_task'
  end

  def create_task
    raise NotImplementedError, 'Must implement create_task'
  end

  def edit_task
    raise NotImplementedError, 'Must implement edit_task'
  end
end

class JsonFile
  include TaskFile

  def initialize(path = 'tasks.json')
    @path = path
  end

  def list_tasks
    JSON.parse File.read(@path)
  end

  def find_task(id)
    list_tasks.find { |task| task['id'] == id }
  end

  def delete_task(id)
    tasks = list_tasks
    task_to_delete = find_task id

    return if task_to_delete.nil?

    tasks.delete_if { |task| task['id'] == id }

    File.write @path, JSON.pretty_generate(tasks) # this should be on another method?

    task_to_delete
  end

  def create_task(title, description = nil)
    task = {
      'id' => SecureRandom.uuid,
      'title' => title,
      'description' => description,
      'done' => false, # I supose we only add pending tasks
    }

    tasks = list_tasks
    tasks << task
    File.write @path, JSON.pretty_generate(tasks)

    task
  end

  def edit_task(id, title: nil, description: nil, done: nil)
    tasks = list_tasks

    index_task_to_edit = tasks.find_index { |task| task['id'] == id }

    return if index_task_to_edit.nil?

    tasks[index_task_to_edit]['title'] = title unless title.nil?
    tasks[index_task_to_edit]['description'] = description unless description.nil?
    tasks[index_task_to_edit]['done'] = done unless done.nil?

    File.write @path, JSON.pretty_generate(tasks)

    tasks[index_task_to_edit]
  end
end

class ArrayFile
  include TaskFile
  def initialize(path = 'tasks.json')
    @tasks = JSON.parse File.read(path)
  end

  def list_tasks
    @tasks
  end

  def find_task(id)
    list_tasks.find { |task| task['id'] == id }
  end

  def delete_task(id)
    tasks = list_tasks
    task_to_delete = Todo.find_task id

    return if task_to_delete.nil?

    tasks.delete_if { |task| task['id'] == id }

    task_to_delete
  end

  def create_task(title, description = nil)
    task = {
      'id' => SecureRandom.uuid,
      'title' => title,
      'description' => description,
      'done' => false, # I supose we only add pending tasks
    }

    tasks = list_tasks
    tasks << task

    task
  end

  def edit_task(id, title: nil, description: nil, done: nil)
    tasks = list_tasks

    index_task_to_edit = tasks.find_index { |task| task['id'] == id }

    return if index_task_to_edit.nil?

    tasks[index_task_to_edit]['title'] = title unless title.nil?
    tasks[index_task_to_edit]['description'] = description unless description.nil?
    tasks[index_task_to_edit]['done'] = done unless done.nil?

    tasks[index_task_to_edit]
  end
end

class Todo
  def initialize(task_file)
    @task_file = task_file
  end

  def list_tasks
    @task_file.list_tasks
  end

  def find_task(id)
    @task_file.find_task id
  end

  def delete_task(id)
    @task_file.delete_task id
  end

  def create_task(title, description = nil)
    @task_file.create_task title, description
  end

  def edit_task(id, title: nil, description: nil, done: nil)
    @task_file.edit_task id, title: title, description: description, done: done
  end
end
