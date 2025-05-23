require 'json'

module Todo
  extend self

  def list_tasks
    JSON.parse File.read('tasks.json')
  end

  def find_task(uuid)
    Todo.list_tasks.find { |task| task['id'] == uuid }

    # task_file = JSON.parse File.read('tasks.json')
    # task_file.select { |task| task['id'] == uuid }.first # || "Task #{uuid} not found"
  end

  def delete_task(uuid)
    task_to_delete = Todo.find_task uuid

    return if task_to_delete.nil?

    tasks_updated = Todo.list_tasks.delete_if { |task| task['id'] == uuid }

    task_to_delete
  end
end
