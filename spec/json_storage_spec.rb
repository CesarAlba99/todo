require 'spec_helper'
require 'tempfile'
require 'json'

RSpec.describe JsonStorage do
  let(:temp_file) { Tempfile.new ['test_tasks', '.json'] }
  let(:temp_path) { temp_file.path }
  let(:json_storage) { JsonStorage.new temp_path }

  let :sample_tasks do
    [
      { id: '12345', title: 'Do my homework', description: 'Do the homework', done: false },
      { id: '67890', title: 'Do ruby practice', description: 'Use codewars for ruby basics', done: true },
    ]
  end

  after do #this is executed when a unit test ends
    temp_file.close
    temp_file.unlink if File.exist? temp_path
  end

  describe '#initialize' do
    it 'sets default path' do
      storage = JsonStorage.new
      expect(storage.instance_variable_get(:@path)).to eq('tasks.json')
    end

    it 'sets custom path' do
      expect(json_storage.instance_variable_get(:@path)).to eq(temp_path)
    end
  end

  describe '#read' do
    context 'when file exists and contains valid JSON' do
      before do 
        File.write temp_path, JSON.pretty_generate(sample_tasks)
      end

      it 'returns parsed JSON with symbolized keys' do
        result = json_storage.read
        expect(result).to eq(sample_tasks)
        expect(result.first.keys).to all(be_a(Symbol))
      end
    end

    context 'when file does not exist' do
      before do
        File.delete temp_path if File.exist? temp_path
      end

      it 'raises TodoFileReadError with file not found message' do
        expect { json_storage.read }.to raise_error(TodoFileReadError, /File not found/)
      end
    end

    context 'when file has invalid JSON' do
      before do
        File.write temp_path, '{ invalid json content }'
      end

      it 'raises TodoFileReadError with JSON parsing error message' do
        expect { json_storage.read }.to raise_error(TodoFileReadError, /JSON parsing error/)
      end
    end

    context 'when file has permission issues' do
      before do
        File.write temp_path, JSON.pretty_generate(sample_tasks)
        File.chmod 0o000, temp_path #change permissions
      end

      after do
        File.chmod 0o644, temp_path # Restore permissions
      end

      it 'raises TodoFileReadError with permission denied message' do
        expect { json_storage.read }.to raise_error(TodoFileReadError, /Permission denied for reading/)
      end
    end
  end

  describe '#write' do
    context 'when writing to valid path' do
      it 'writes tasks as pretty JSON' do
        json_storage.write sample_tasks

        file_content = File.read temp_path
        parsed_content = JSON.parse file_content, symbolize_names: true

        expect(parsed_content).to eq(sample_tasks)
        expect(file_content).to include("\n") # Pretty formatted
      end

      it 'overwrites existing content' do
        initial_tasks = [{ id: '111', title: 'Initial task', done: false }]
        json_storage.write initial_tasks
        json_storage.write sample_tasks

        result = json_storage.read
        expect(result).to eq(sample_tasks)
        expect(result.length).to eq(2)
      end
    end

    context 'when directory does not exist' do
      let(:invalid_path) { '/noexists/directory/tasks.json' }
      let(:invalid_json_storage) { JsonStorage.new invalid_path }

      it 'raises TodoFileWriteError with file not found message' do
        expect { invalid_json_storage.write(sample_tasks) }.to raise_error(TodoFileWriteError, /File or directory not found/)
      end
    end

    context 'when file has no write permissions' do
      before do
        File.write temp_path, '[]'
        File.chmod 0o444, temp_path # Read only
      end

      after do
        File.chmod 0o644, temp_path # Restore 
      end

      it 'raises TodoFileWriteError with permission denied message' do
        expect { json_storage.write(sample_tasks) }.to raise_error(TodoFileWriteError, /Permission denied for writing/)
      end
    end
  end

  describe 'integration with Todo class' do
    let(:todo) { Todo.new json_storage }

    before do
      json_storage.write sample_tasks
    end

    it 'works correctly with Todo operations' do
      tasks = todo.list_tasks
      expect(tasks.length).to eq(2)

      # Create a new task
      new_task = todo.create_task 'New task', description: 'Test task'
      expect(new_task).to include(title: 'New task')

      # Verify a new task
      reloaded_tasks = JsonStorage.new(temp_path).read
      expect(reloaded_tasks.length).to eq(3)
      expect(reloaded_tasks.last).to include(title: 'New task')
    end
  end
end
