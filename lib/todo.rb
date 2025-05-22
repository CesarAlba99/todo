require 'json'

module Todo
  extend self

  def list_tasks
    JSON.parse File.read('tasks.json')
  end
end
