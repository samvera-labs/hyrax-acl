# frozen_string_literal: true

RSpec.describe Hyrax::Acl::Group, type: :model do
  let(:name) { 'etaoin' }
  let(:group) { described_class.new(name) }

  describe '.from_agent_key' do
    it 'returns an equivalent group' do
      expect(described_class.from_agent_key(group.agent_key)).to eq group
    end
  end

  describe '#name' do
    it 'returns the name' do
      expect(group.name).to eq name
    end
  end

  describe '#agent_key' do
    it 'returns the name prefixed with the name prefix' do
      expect(group.agent_key).to eq described_class.name_prefix + group.name
    end
  end
end
