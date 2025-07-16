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
    repository.find_task_by_id id
  end

  def delete_task(id)
    list_tasks
    task_to_delete = find_task id

    return if task_to_delete.nil?

    repository.delete_task_by_id task_to_delete.id
  end

  def create_task(title, **attributes)
    raise 'title is required to create a task' if !title.is_a?(String) || title.empty?

    new_task = (attributes.merge title: title).merge user_id: user.id

    repository.create_user_task({
      user_id: new_task[:user_id],
      title: new_task[:title],
      description: new_task.fetch(:description, nil),
      deadline: new_task.fetch(:deadline, nil),
      done: new_task.fetch(:done, false),
    })
  end

  def edit_task(id, **attributes)
    task = repository.find_task_by_id id

    return if task.nil?

    attributes.merge! id: task.id

    repository.edit_user_task_by_id({
      id: attributes[:id],
      title: attributes.fetch(:title, task.title),
      description: attributes.fetch(:description, task.description),
      deadline: attributes.fetch(:deadline, task.deadline),
      done: attributes.fetch(:done, task.done),
    })
  end

  private

  def repository
    @repository ||= Todo::Repository.new
  end
end
