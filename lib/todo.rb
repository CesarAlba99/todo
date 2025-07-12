require 'json'
require 'securerandom'
require 'csv'
require 'pg'
require 'sequel'

require_relative 'todo/errors'
require_relative 'todo/storage'
require_relative 'todo/repository'
require_relative 'todo/entities'

class Todo
  attr_reader :user

  def initialize(username, force: false)
    @user = repository.find_user_by_username username

    return unless user.nil?
    raise Todo::InvalidUsernameError.new('username no found') unless force

    @user = repository.create_user username
  end

  def list_tasks
    repository.list_tasks_by_user_id user.id
  end

  def find_task(id)
    # list_tasks.find { |task| task[:id] == id }
    repository.find_task_by_id id
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

  private

  def repository
    @repository ||= Todo::Repository.new
  end
end
