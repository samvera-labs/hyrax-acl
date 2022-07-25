# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Acl::AccessControl do
  subject(:access_control) { described_class.new }
  let(:adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }

  let(:controlled_resource_class) { Class.new(Valkyrie::Resource) }
 let(:controlled_resource) { controlled_resource_class.new(id: 'etaoin') }

  let(:resource_klass) { Class.new(Valkyrie::Resource) }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  it 'can save with default adapter' do
    expect(persister.save(resource: access_control)).to be_persisted
  end

  it 'saves an empty set of permissions by default' do
    saved = persister.save(resource: access_control)

    expect(query_service.find_by(id: saved.id).permissions).to be_empty
  end

  describe '.for' do
    let(:retrieved_access_control) do
      described_class.for(
        resource: controlled_resource,
        query_service: query_service
      )
    end

    it 'returns an access control model for the resource given' do
      expect(retrieved_access_control)
        .to have_attributes(access_to: controlled_resource.id)
    end

    it 'returns an empty access control for an unpersisted resource' do
      expect(retrieved_access_control)
        .to have_attributes(permissions: be_empty)
    end

    context 'when an AccessControl already exists' do
      let(:controlled_resource) { persister.save(resource: controlled_resource_class.new) }

      before do
        persister.save(
          resource: described_class.new(access_to: controlled_resource.id)
        )
      end

      it 'reloads persisted data' do
        expect(retrieved_access_control).to be_persisted
      end
    end
  end

  describe '#access_to' do
    let(:target_id) { controlled_resource.id }

    it 'grants access to a specific resource' do
      expect { access_control.access_to = target_id }
        .to change { access_control.access_to }
        .to target_id
    end

    context 'with permissions and target' do
      let(:access_control) { described_class.new(access_to: target_id, permissions: [permission]) }
      let(:permission) { Hyrax::Acl::Permission.new(mode: :read, agent: 'moomin', access_to: target_id) }

      it 'retains its own access_to target' do
        expect(persister.save(resource: access_control))
          .to have_attributes access_to: access_control.access_to
      end

      it 'retains access_to target on the created permissions' do
        expect(persister.save(resource: access_control))
          .to have_attributes(
            permissions: contain_exactly(have_attributes(
              mode: permission.mode,
              agent: permission.agent,
              access_to: permission.access_to
            ))
          )
      end
    end
  end

  describe '#permissions' do
    let(:permission) { Hyrax::Acl::Permission.new(mode: :read, agent: 'moomin', access_to: target_id) }
    let(:target_id) { controlled_resource.id }

    it 'maintains a list of permission policies' do
      expect { access_control.permissions = [permission] }
        .to change { access_control.permissions }
        .to contain_exactly(permission)
    end

    context 'with permissions' do
      before { access_control.permissions = [permission] }

      it 'can save with default adapter' do
        expect(persister.save(resource: access_control))
          .to have_attributes(
            permissions: contain_exactly(have_attributes(
              mode: permission.mode,
              agent: permission.agent
            ))
          )
      end

      it 'can delete permissions' do
        saved = persister.save(resource: access_control)

        updated = saved.dup # memory adapter updates saved resources inline!
        updated.permissions = []

        expect { persister.save(resource: updated) }
          .to change { query_service.find_by(id: saved.id).permissions }
          .from(contain_exactly(have_attributes(mode: permission.mode,
                                                agent: permission.agent)))
          .to be_empty
      end
    end

    context 'with group permissions' do
      let(:permission) { Hyrax::Acl::Permission.new(mode: :read, agent: 'group/public', access_to: target_id) }

      it 'can save a group permission' do
        access_control.permissions = [permission]

        expect(persister.save(resource: access_control))
          .to have_attributes(
            permissions: contain_exactly(have_attributes(
              mode: permission.mode,
              agent: permission.agent
            ))
          )
      end
    end
  end
end
