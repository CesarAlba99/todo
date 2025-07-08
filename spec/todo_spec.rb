RSpec.describe Todo do
  #  let(:json_storage) { JsonStorage.new }
  #  let(:csv_storage) { CsvStorage.new }

  let :sample_tasks do
    [{ id: '12345', title: 'Do my homework', description: 'Do the poo hw', done: false },
     { id: '123456', title: 'Buy a new tv', description: 'Buy a new tv for me', done: false },]
  end

  let(:memory_storage) { Todo::Storage::MemoryStorage.new sample_tasks }
  let(:todo) { Todo.new memory_storage }

  let(:existing_id) { '12345' }
  let(:unknown_id) { 'noid1234' }
  let(:existing_id2) { '123456' }

  describe '.list_tasks' do
    let(:result) { todo.list_tasks }

    it 'returns a list of tasks' do
      expect(result).to all(be_a(Hash))
    end
  end

  describe '.find_task' do
    let(:id) { existing_id }
    let(:result) { todo.find_task id }

    it 'finds the desired task' do
      expect(result).to be_a(Hash).and include(id: id)
    end

    context 'With unknown ID' do
      let(:id) { unknown_id }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '.delete_task' do
    let(:id) { existing_id }
    let(:result) { todo.delete_task id }

    it 'retrieves the deleted task' do
      expect(result).to be_a(Hash).and include(id: id)
    end

    context 'With unknown ID' do
      let(:id) { 'p54470e73-2c2c-4d19-a2b1-f8cea8115f' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '.create_task' do
    let(:title) { 'Do the dishes' }
    let(:description) { 'I have to do the dishes' }
    let(:done) { false }
    let(:result) { todo.create_task title, description: description, done: done }

    it 'creates a new task' do
      expect(result).to be_a(Hash).and include(
        title: title,
        description: description,
        done: done
      )
    end
  end

  describe '.edit_task' do
    let(:id) { existing_id2 }
    let(:title) { 'My task edited' }
    let(:description) { 'Description of the task edited' }
    let(:done) { true }

    let(:result) { todo.edit_task id, title: title, description: description, done: done }

    it 'edit a task' do
      expect(result).to be_a(Hash).and include(
        id: id,
        title: title,
        description: description,
        done: done
      )
    end
    context 'With unknown ID' do
      let(:id) { 'u54470e73-2c2c-4d19-a2b1-f8cea8115f' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end
end
