# frozen_string_literal: true

module Hyrax
  module Acl
    ##
    # A ChangeSet for Hyrax::Acl::AccessControl.
    class AccessControlChangeSet < Valkyrie::ChangeSet
      property :access_to, type: Valkyrie::Types::ID, default: nil
      property :permissions, type: Valkyrie::Types::Set.of(Hyrax::Acl::Permission), default: nil
    end
  end
end
