RSpec.describe Todo do
  describe '.hi' do
    it 'salutes' do
      expect(Todo.hi('Omar')).to eq('Hi Omar')
    end
  end
end
