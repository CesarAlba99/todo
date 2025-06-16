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

  describe '#read' do
    before do
      CSV.open temp_path, 'w', write_headers: true, headers: %i[id title description done] do |csv|
        csv << ['12345', 'Do my homework', 'Do the homework', 'false']
        csv << ['67890', 'Do ruby practice', 'Use codewars for practice', 'true']
      end
    end
    context 'when file exists and contains valid CSV' do
      let(:result) { csv_storage.read }
      it 'reads the desired file' do
        expect(result).to all(be_a(Hash))
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
  end

  describe '#write' do
    let(:result) { csv_storage.write [{ id: '1', title: 'first task' }] }

    it 'writes the desired file' do
      expect(result).to all(be_a(Hash))
    end
  end
end
