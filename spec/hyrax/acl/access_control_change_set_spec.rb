# frozen_string_literal: true

RSpec.describe Hyrax::Acl::AccessControlChangeSet do
  subject(:change_set) { described_class.new(access_control) }
  let(:access_control) { Hyrax::Acl::AccessControl.new }

  let(:permission) { Hyrax::Acl::Permission.new(mode: :read, agent: 'moomin', access_to: 'resource1') }

  describe "changed?" do
    it "is true after adding a permission" do
      expect { change_set.permissions = [permission] }
        .to change { change_set.changed? }
        .from(false)
        .to true
    end

    context "with existing permissions" do
      let(:access_control) { Hyrax::Acl::AccessControl.new(permissions: [permission] ) }

      it "is false when adding it again" do
        expect { change_set.permissions << permission }
          .not_to change { change_set.changed? }
          .from(false)
      end

      it "is false when adding it many times" do
        change_set.permissions << permission
        change_set.permissions << permission
        change_set.permissions << permission

        expect { change_set.permissions << permission }
          .not_to change { change_set.changed? }
          .from(false)
      end

      it "is true when removing the permission" do
        expect { change_set.permissions -= [permission] }
          .to change { change_set.changed? }
          .from(false)
          .to true
      end

      it "is false when removing a different permission" do
        other_permission =
          Hyrax::Acl::Permission.new(mode: :read, agent: 'snufkin', access_to: 'resource1')

        expect { change_set.permissions -= [other_permission] }
          .not_to change { change_set.changed? }
          .from(false)
      end
    end
  end

  describe "#permission" do
    it "contains the permission" do
      expect { change_set.permissions = permission }
        .to change { change_set.permissions }
        .from(be_empty)
        .to contain_exactly(permission)
    end
  end
end
