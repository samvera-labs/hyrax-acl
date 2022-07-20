# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Acl::AccessControlList do
  describe '#grant discover access' do
    subject { described_class.new(access_control: access_control) }

    let(:agent) { Hyrax::Acl::Agent.new('hyrax_group/superskunk') }
    let(:target_id) { Valkyrie::ID.new('moomin') }
    let(:access_control) { Hyrax::Acl::AccessControl.new(access_to: target_id, permissions: [permission]) }
    let(:permission) { Hyrax::Acl::Permission.new(mode: mode, agent: agent.agent_key, access_to: target_id) }

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
end
