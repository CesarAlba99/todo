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

  after do # this is executed when a unit test ends
    temp_file.close
    temp_file.unlink if File.exist? temp_path
  end

  describe '#read' do
    context 'when file exists and contains valid JSON' do
      let(:result) { json_storage.read }

      before { JSON.dump([{ id: '1', title: 'first task', done: false }], File.open(temp_file, 'w')) }

      it 'reads the desired file' do
        expect(result).to all(be_a(Hash))
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
  end

  describe '#write' do
    let(:result) { json_storage.write sample_tasks }
    it 'writes the desired file' do
      expect(result).to be_a(File)
    end
  end
end
