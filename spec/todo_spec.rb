RSpec.describe Todo do
  let(:json_storage) { JsonMyStorage.new }
  let(:memory_storage) { MemoryMyStorage.new }
  let(:todo) { Todo.new memory_storage }

  describe '.list_tasks' do
    let(:result) { todo.list_tasks }

    it 'returns a list of tasks' do
      expect(result).to all(be_a(Hash))
    end
  end

  describe '.find_task' do
    let(:id) { '956ee9e9-1c30-4412-bcd9-0f0fc98e254a' }
    let(:result) { todo.find_task id }

    it 'finds the desired task' do
      expect(result).to be_a(Hash)
      expect(result['id']).to eq(id)
    end

    context 'With unknown ID' do
      let(:id) { 'j956ee9e9-1c30-4412-bcd9-0f0fc98e254a' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '.delete_task' do
    let(:id) { '956ee9e9-1c30-4412-bcd9-0f0fc98e254a' }
    let(:result) { todo.delete_task id }

    it 'retrieves the deleted task' do
      expect(result).to be_a(Hash)
      expect(result['id']).to eq(id)
    end

    context 'With unknown ID' do
      let(:id) { 'p54470e73-2c2c-4d19-a2b1-f8cea8115f' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '.add_task' do
    let(:title) { 'Do homework' }
    let(:description) { 'I have to do my homework' }
    let(:done) { false }
    let(:result) { todo.add_task title, description }

    it 'creates a new task' do
      expect(result).to be_a(Hash)
      expect(result['title']).to eq(title)
      expect(result['description']).to eq(description)
      expect(result['done']).to eq(done)
    end
  end

  describe '.edit_task' do
    let(:id) { '4894b6bd-2899-43b6-bd94-11f2b7248d38' }
    let(:title) { 'My first task edited' }
    let(:description) { 'Description of the first task edited' }
    let(:done) { true }

    let(:result) { todo.edit_task id, title: title, description: description, done: done }

    it 'edit a task' do
      expect(result).to be_a(Hash)

      expect(result['id']).to eq(id)
      expect(result['title']).to eq(title)
      expect(result['description']).to eq(description)
      expect(result['done']).to eq(done)
    end
    context 'With unknown ID' do
      let(:id) { 'u54470e73-2c2c-4d19-a2b1-f8cea8115f' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end
end
