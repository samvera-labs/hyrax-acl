# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Acl::AccessControlList do
  subject(:acl) do
    described_class.new(resource: resource,
                        persister: persister,
                        query_service: query_service)
  end

  let(:adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:persister)     { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource) { persister.save(resource: resource_class.new) }
  let(:resource_class) { Class.new(Valkyrie::Resource) }

  let(:permission) do
    Hyrax::Acl::Permission.new(access_to: resource.id, mode: :read, agent: 'fake_user_id')
  end

  before do
    query_service.custom_queries.register_query_handler(
      Hyrax::Acl::CustomQueries::FindAccessControl
    )
  end

  describe "read API" do
    let(:agent) { Hyrax::Acl::Group.new('superskunk') }

    before do
      acl << permission
    end

    let(:permission) do
      Hyrax::Acl::Permission.new(access_to: resource.id, mode: mode, agent: agent.agent_key)
    end

    context "discover grant" do
      let(:mode) { :discover }

      it 'gives a discover permission' do
        expect(subject.has_discover?(agent: agent))
          .to be true
      end
    end

    context "read grant" do
      let(:mode) { :read }

      it 'gives a read permission' do
        expect(subject.has_read?(agent: agent))
          .to be true
      end
    end

    context "edit grant" do
      let(:mode) { :edit }

      it 'gives an edit permission' do
        expect(subject.has_edit?(agent: agent))
          .to be true
      end
    end
  end

  describe 'grant DSL' do
    let(:mode) { :read }
    let(:user) { Hyrax::Acl::Agent.new('user1') }
    let(:group) { Hyrax::Acl::Group.new("public") }

    describe '#grant' do
      it 'grants a permission' do
        expect { acl.grant(mode).to(user) }
          .to change { acl.permissions }
          .to contain_exactly(have_attributes(mode: mode,
                                              agent: user.agent_key.to_s,
                                              access_to: resource.id))
      end

      it 'grants a permission to a group' do
        expect { acl.grant(mode).to(group) }
          .to change { acl.permissions }
          .to contain_exactly(have_attributes(mode: mode,
                                              agent: group.agent_key,
                                              access_to: resource.id))
      end
    end

    describe '#revoke' do
      before do
        acl.grant(mode).to(user)
        acl.save
      end

      it 'revokes a permission' do
        expect { acl.revoke(mode).from(user) }
          .to change { acl.permissions }
          .to be_empty
      end
    end
  end

  describe '#<<' do
    it 'adds the new permission with access_to' do
      expect { acl << permission }
        .to change { acl.permissions }
        .to contain_exactly(have_attributes(mode: permission.mode,
                                            agent: permission.agent,
                                            access_to: resource.id))
    end
  end

  describe '#delete' do
    it 'does nothing when the permission is not in the set' do
      expect { acl.delete(permission) }
        .not_to change { acl.permissions }
        .from be_empty
    end

    context 'when the permission exists' do
      before { acl << permission }

      it 'removes the permission' do
        expect { acl.delete(permission) }
          .to change { acl.permissions }
          .from(contain_exactly(have_attributes(mode: permission.mode,
                                                agent: permission.agent,
                                                access_to: resource.id)))
          .to be_empty
      end
    end
  end

  describe '#permissions' do
    it 'is empty by default' do
      expect(acl.permissions).to be_empty
    end
  end

  describe '#pending_changes?' do
    it { is_expected.not_to be_pending_changes }

    context 'with an added acl' do
      before { acl << permission }

      it { is_expected.to be_pending_changes }

      context 'and it is saved' do
        before { acl.save }

        it { is_expected.not_to be_pending_changes }

        context 'and it is removed' do
          before { acl.delete(permission) }

          it { is_expected.to be_pending_changes }
        end

        context 'and the same permission is added again' do
          before { acl << permission }

          xit { is_expected.not_to be_pending_changes }
        end
      end
    end
  end

  describe '#save' do
    it 'leaves permissions unchanged by default' do
      expect { acl.save }
        .not_to change { acl.permissions }
        .from be_empty
    end

    it 'does not yield' do
      expect { |block| acl.save(&block) }.not_to yield_control
    end

    context 'with additions' do
      let(:permissions)      { [permission, other_permission] }
      let(:other_permission) do
        Hyrax::Acl::Permission.new(access_to: resource.id, mode: :edit, agent: 'fake_user_id')
      end

      before { permissions.each { |p| acl << p } }

      it 'saves the permission policies' do
        expect { acl.save }
          .to change { Hyrax::Acl::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          .to contain_exactly(*permissions)
      end

      it 'yields itself' do
        expect { |block| acl.save(&block) }.to yield_with_args(acl)
      end
    end

    context 'with deletions' do
      let(:permissions)      { [permission, other_permission] }
      let(:other_permission) do
        Hyrax::Acl::Permission.new(access_to: resource.id, mode: :edit, agent: 'fake_user_id')
      end

      before do
        permissions.each { |p| acl << p }
        acl.save
      end

      it 'deletes the permission policy' do
        delete_me = acl.permissions.first
        acl.delete(delete_me)
        rest = acl.permissions.clone

        expect { acl.save }
          .to change { Hyrax::Acl::AccessControl.for(resource: resource, query_service: acl.query_service).permissions }
          .to contain_exactly(*rest)
      end

      it 'yields itself' do
        delete_me = acl.permissions.first
        acl.delete(delete_me)
        rest = acl.permissions.clone

        expect { |block| acl.save(&block) }.to yield_with_args(acl)
      end
    end
  end
end
