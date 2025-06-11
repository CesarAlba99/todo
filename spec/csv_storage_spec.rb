require 'spec_helper'
require 'tempfile'
require 'csv'

RSpec.describe CsvStorage do
  let(:temp_file) { Tempfile.new ['test_tasks', '.csv'] }
  let(:temp_path) { temp_file.path }
  let(:csv_storage) { CsvStorage.new temp_path }

  let :sample_tasks do
    [
      { id: '12345', title: 'Do my homework', description: 'Do the homework', done: false },
      { id: '67890', title: 'Do ruby practice', description: 'Use codewars for practice', done: true },
    ]
  end

  after do
    temp_file.close
    temp_file.unlink if File.exist? temp_path
  end

  describe '#initialize' do
    it 'sets default path' do
      storage = CsvStorage.new
      expect(storage.instance_variable_get(:@path)).to eq('tasks.csv')
    end

    it 'sets custom path' do
      expect(csv_storage.instance_variable_get(:@path)).to eq(temp_path)
    end
  end

  describe '#read' do
    context 'when file exists and contains valid CSV' do
      before do
        CSV.open temp_path, 'w', write_headers: true, headers: %i[id title description done] do |csv|
          csv << ['12345', 'Do my homework', 'Do the homework', 'false']
          csv << ['67890', 'Do ruby practice', 'Use codewars for practice', 'true']
        end
      end

      it 'returns parsed CSV with symbolized keys' do
        result = csv_storage.read
        expect(result).to eq(sample_tasks)
        expect(result.first.keys).to all(be_a(Symbol))
      end

      it 'correctly converts done field to boolean' do
        result = csv_storage.read
        expect(result.first[:done]).to be false
        expect(result.last[:done]).to be true
      end
    end

    context 'when file does not exist' do
      before do
        File.delete temp_path if File.exist? temp_path
      end

      it 'raises TodoFileReadError with file not found message' do
        expect { csv_storage.read }.to raise_error(TodoFileReadError, /File not found/)
      end
    end

    context 'when file has malformed CSV' do
      before do
        File.write temp_path, "id,title,description\n12345,\"unclosedquote,test"
      end

      it 'raises TodoFileReadError with malformed CSV message' do
        expect { csv_storage.read }.to raise_error(TodoFileReadError, /Malformed CSV file/)
      end
    end

    context 'when file has permission issues' do
      before do
        CSV.open temp_path, 'w', write_headers: true, headers: %i[id title] do |csv|
          csv << %w[123 Test]
        end
        File.chmod 0o000, temp_path # No read
      end

      after do
        File.chmod 0o644, temp_path # Restore
      end

      it 'raises TodoFileReadError with permission denied message' do
        expect { csv_storage.read }.to raise_error(TodoFileReadError, /Permission denied for reading/)
      end
    end
  end

  describe '#write' do
    context 'when writing to valid path' do
      it 'writes tasks as CSV with headers' do
        csv_storage.write sample_tasks

        # Read the file directly to verify format
        content = File.read temp_path
        lines = content.split "\n"

        expect(lines.first).to eq('id,title,description,done')
        expect(lines.length).to eq(3) # headers and the sample tasks
      end

      it 'overwrites existing content' do
        initial_tasks = [{ id: '111', title: 'Initial task', done: false }]
        csv_storage.write initial_tasks
        csv_storage.write sample_tasks

        result = csv_storage.read
        expect(result).to eq(sample_tasks)
        expect(result.length).to eq(2)
      end
    end

    context 'when directory has write permission issues' do
      before do
        CSV.open(temp_path, 'w') { |csv| csv << ['test'] }
        File.chmod 0o444, temp_path # Read
      end

      after do
        File.chmod 0o644, temp_path # Restore
      end

      it 'raises TodoFileWriteError with permission denied message' do
        expect { csv_storage.write(sample_tasks) }.to raise_error(TodoFileWriteError, /Permission denied for writing/)
      end
    end
  end

  describe 'integration with Todo class' do
    let(:todo) { Todo.new csv_storage }

    before do
      csv_storage.write sample_tasks
    end

    it 'works correctly with Todo operations' do
      tasks = todo.list_tasks
      expect(tasks.length).to eq(2)

      # Create a new task
      new_task = todo.create_task 'New CSV task', description: 'Test CSV task', done: false
      expect(new_task).to include(title: 'New CSV task')

      # Verify it was persisted
      reloaded_tasks = CsvStorage.new(temp_path).read
      expect(reloaded_tasks.length).to eq(3)
      expect(reloaded_tasks.last).to include(title: 'New CSV task')
    end

    it 'maintains boolean conversion through Todo operations' do
      # Edit a task to change done status
      updated_task = todo.edit_task '12345', done: true
      expect(updated_task[:done]).to be true

      # Verify persistence and boolean conversion
      reloaded_tasks = CsvStorage.new(temp_path).read
      updated_task_reloaded = reloaded_tasks.find { |task| task[:id] == '12345' }
      expect(updated_task_reloaded[:done]).to be true
      expect(updated_task_reloaded[:done]).to be_a(TrueClass)
    end
  end
end
