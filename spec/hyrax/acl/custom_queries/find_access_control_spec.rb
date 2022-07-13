# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Acl::CustomQueries::FindAccessControl do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource_class) { Class.new(Valkyrie::Resource) }

  describe '#find_access_control' do
    context 'for missing object' do
      let(:resource) { resource_class.new }

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_access_control_for(resource: resource) }
          .to raise_error { Valkyrie::Persistence::ObjectNotFoundError }
      end
    end

    context 'when an acl exists' do
      let(:acl) do
        persister.save(
          resource: Hyrax::Acl::AccessControl.new(access_to: resource.id)
        )
      end
      let(:resource) { persister.save(resource: resource_class.new) }

      before { acl } # ensure the acl gets saved

      it 'returns the acl' do
        expect(query_handler.find_access_control_for(resource: resource))
          .to eq acl
      end
    end

    context 'for another class purporting to provide access_to' do
      let(:malicious_acl) { malicious_acl_class }
      let(:resource) { persister.save(resource: resource_class.new) }

      let(:malicious_acl_class) do
        Class.new(Valkyrie::Resource) do
          attribute :access_to, Valkyrie::Types::ID
        end
      end

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_access_control_for(resource: resource) }
          .to raise_error { Valkyrie::Persistence::ObjectNotFoundError }
      end
    end
  end
end
