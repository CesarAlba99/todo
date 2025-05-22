require 'json'

module Todo
  extend self

  def list_tasks
    JSON.parse File.read('tasks.json')
  end

  def find(uuid)
    task_file = JSON.parse File.read('tasks.json')
    task_file.select { |task| task['id'] == uuid }.first || "Task #{uuid} not found"
  end
end
