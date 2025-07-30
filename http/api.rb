require 'sinatra'
require_relative '../lib/todo'

class Api < Sinatra::Base
  set :environment, :production
  set :default_content_type, :json
  disable :dump_errors, :raise_errors

  before do
    @json_params = {}

    if request.content_type == 'application/json'
      begin
        body_content = request.body.read
        @json_params = JSON.parse(body_content) unless body_content.empty?
      rescue StandardError => e
        puts "Error processing JSON: #{e.message}"
        @json_params = {}
      end
    end
  end

  error do
    e = env['sinatra.error']
    [500, { error: { message: e.message } }.to_json]
  end

  def get_todo_instance(username)
    Todo.new username
  rescue Todo::InvalidUsernameError => e
    error_response 404, e.message
  end

  def error_response(status_code, message)
    halt status_code, { error: { message: message } }.to_json
  end

  def parse_epoch_to_timestamp(epoch_string)
    return nil if epoch_string.nil? || epoch_string.empty?

    Time.at epoch_string.to_i
  rescue ArgumentError
    nil
  end

  get '/tasks' do
    username = params['username']

    todo = get_todo_instance username

    done, title, start_deadline, end_deadline = params.values_at(
      :done,
      :title,
      :start_deadline,
      :end_deadline
    )

    unless done.nil?
      done =
        case done
        when 'true', 't', '1' then true
        when 'false', 'f', '0' then false
        else
          raise "Invalid parameter value #{done}.Expected: true, false."
        end
    end

    unless start_deadline.nil?
      start_epoch = start_deadline
      start_deadline = parse_epoch_to_timestamp start_deadline
      raise "Invalid start_deadline, expected a valide epoch: #{start_epoch}" if start_deadline.nil?
    end

    unless end_deadline.nil?
      end_epoch = end_deadline
      end_deadline = parse_epoch_to_timestamp end_deadline
      raise "Invalid end_deadline, expected a valid epoch: #{end_epoch}" if end_deadline.nil?
    end

    { result: todo.list_tasks({
      title: title,
      done: done,
      start_deadline: start_deadline,
      end_deadline: end_deadline,
    }) }.to_json
  rescue StandardError => e
    error_response 400, e.message
  end

  post '/tasks' do
    username = @json_params['username']

    title = @json_params['title']
    error_response 400, 'title is required' if title.nil? || title.empty?

    todo = get_todo_instance username

    description = @json_params['description']
    done = @json_params['done']
    project_id = @json_params['project_id']
    deadline = @json_params['deadline']

    unless done.nil?
      done = case done.to_s.downcase
             when 'true', 't', '1' then true
             when 'false', 'f', '0' then false
             else
               raise "Invalid parameter value #{done}. Expected: true, false."
             end
    end

    unless deadline.nil?
      deadline_epoch = deadline
      deadline = parse_epoch_to_timestamp deadline.to_s
      raise "Invalid deadline, expected a valid epoch: #{deadline_epoch}" if deadline.nil?
    end

    task_attributes = {}
    task_attributes[:description] = description if description
    task_attributes[:done] = done unless done.nil?
    task_attributes[:project_id] = project_id if project_id
    task_attributes[:deadline] = deadline if deadline

    created_task = todo.create_task(title, **task_attributes)

    { result: created_task }.to_json
  rescue StandardError => e
    error_response 400, e.message
  end
end
