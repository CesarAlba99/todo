require 'sinatra'
require_relative '../lib/todo'

class Api < Sinatra::Base
  set :environment, :production
  set :default_content_type, :json
  disable :dump_errors, :raise_errors

  before do
    @json_params = {}

    if ['POST'].include?(request.request_method)
    unless request.content_type == 'application/json'
      error_response(400,"Content-Type must be application/json")
    end

    body_content = request.body.read
    @json_params = JSON.parse(body_content, symbolize_names: true) unless body_content.empty?
    end
  end

  error do 
    e = env['sinatra.error']
    [500, { error: { message: e.message } }.to_json]
  end

  error JSON::ParserError do 
    [400, { error: { message: "Invalid JSON request" } }.to_json]
  end

  def get_todo_instance
    Todo.new "OmarAlba"
  end

  def error_response(status_code, message)
    halt status_code, { error: { message: message } }.to_json
  end

  def parse_epoch_to_timestamp(epoch_string)
    return nil if epoch_string.nil? || epoch_string.empty?

    epoch_int = Integer(epoch_string)
    Time.at epoch_int
  rescue StandardError
    nil
  end

  get '/tasks' do
    todo = get_todo_instance 

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
      raise "Invalid start_deadline, expected a valid epoch: #{start_epoch}" if start_deadline.nil?
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
  end

  post '/tasks' do
    title = @json_params[:title]
    error_response 400, 'title is required' if title.nil? || title.empty?

    todo = get_todo_instance 

    done = @json_params[:done]
    deadline = @json_params[:deadline]
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
    task_attributes[:description] = @json_params[:description]
    task_attributes[:done] = done
    task_attributes[:project_id] = @json_params[:project_id]
    task_attributes[:deadline] = deadline

    created_task = todo.create_task(title, **task_attributes)

    { result: created_task }.to_json
  end

  put '/task/:id' do
    task_id = params[:id]
    error_response(400, 'task id is required') if task_id.nil? || task_id.empty?
    
    validate_uuid!(task_id)
    
    todo = get_todo_instance 
    
    existing_task = todo.find_task(task_id)
    error_response(404, 'Task not found') if existing_task.nil?
    
    title = @json_params[:title]
    description = @json_params[:description] 
    done = @json_params[:done]
    project_id = @json_params[:project_id]
    deadline = @json_params[:deadline]
    
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
        deadline = parse_epoch_to_timestamp(deadline.to_s)
        raise "Invalid deadline, expected a valid epoch: #{deadline_epoch}" if deadline.nil?
    end
    
    update_attributes = {}
    update_attributes[:title] = title if title
    update_attributes[:description] = description if @json_params.key?('description')
    update_attributes[:done] = done unless done.nil?
    update_attributes[:project_id] = project_id if @json_params.key?('project_id')
    update_attributes[:deadline] = deadline if @json_params.key?('deadline')
    
    updated_task = todo.edit_task(task_id, **update_attributes)
    error_response(500, 'Failed to update task') if updated_task.nil?
    
    { result: updated_task }.to_json
end

get '/task/:id' do
    task_id = params[:id]
    error_response(400, 'task id is required') if task_id.nil? || task_id.empty?
    
    validate_uuid!(task_id)
    
    todo = get_todo_instance
    
    task = todo.find_task(task_id)
    error_response(404, 'Task not found') if task.nil?
    
    { result: task }.to_json
end

delete '/task/:id' do
    task_id = params[:id]
    error_response(400, 'task id is required') if task_id.nil? || task_id.empty?
    
    validate_uuid!(task_id)
    
    todo = get_todo_instance 
    
    existing_task = todo.find_task(task_id)
    error_response(404, 'Task not found') if existing_task.nil?
    
    deleted_task = todo.delete_task(task_id)
    
    { result: deleted_task }.to_json
end
def valid_uuid?(uuid)
  uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
  
  return false if uuid.nil? || uuid.empty?
  uuid_regex.match?(uuid)
end

def validate_uuid!(uuid)
  error_response(400, "Invalid UUID format.") unless valid_uuid?(uuid)
end
end
