RSpec.describe Todo do
  let(:todo) { Todo }
  describe '.list_tasks' do
    let(:result) { todo.list_tasks }

    it 'returns a list of tasks' do
      expect(result).to all(be_a(Hash))
    end
  end
  
  describe '.find_task' do
    let(:id) {"550e8400-e29b-41d4-a716-446655440001"}
    let(:result) {todo.find_task id}

    it 'finds the desired task' do
      expect(result).to be_a(Hash)
      expect(result['id']).to eq(id)
    end

    context 'With unknown ID' do
      let(:id) {"54470e73-2c2c-4d19-a2b1-f8cea8115f"}

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  
  describe '.delete_task' do
    let(:id) {"550e8400-e29b-41d4-a716-446655440001"}
    let(:result) {todo.delete_task id}

    it 'retrieves the deleted task' do
      expect(result).to be_a(Hash)
      expect(result['id']).to eq(id)
    end


    context 'With unknown ID' do
      let(:id) {"54470e73-2c2c-4d19-a2b1-f8cea8115f"}

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end



end

