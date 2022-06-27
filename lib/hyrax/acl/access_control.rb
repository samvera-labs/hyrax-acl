# frozen_string_literal: true

module Hyrax
  module Acl
    ##
    # A list of permissions pertaining to a specific object.
    #
    # `AccessControl`s consist of a set of permissions and an `#access_to`
    # reference to the object that set governs.
    #
    # @see Hyrax::AccessControlList for a low level DSL for managing
    #   `AccessControl` and `Permission` relationships for `Hyrax::Resource`
    # @see Hyrax::PermissionManager for `read_groups`/`read_users` style setters
    #   and getters
    # @see Hyrax::VisibilityWriter, Hyrax::VisibilityReader for
    #   "open"/"restricted" style visibility management
    class AccessControl < Valkyrie::Resource
      ##
      # @!attribute [rw] access_to
      #   Supports query for ACLs at the resource level. Permissions should be
      #   grouped under an AccessControl with a matching `#access_to` so they can
      #   be retrieved in batch.
      #
      #   @return [Valkyrie::ID] the id of the Resource these permissions apply to
      # @!attribute [rw] permissions
      #   @return [Enumerable<Hyrax::Acl::Permission>]
      attribute :access_to,   Valkyrie::Types::ID
      attribute :permissions, Valkyrie::Types::Set.of(Hyrax::Acl::Permission)
    end
  end
end
