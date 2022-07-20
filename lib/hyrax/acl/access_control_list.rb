# frozen_string_literal: true

module Hyrax
  module Acl
    ##
    # @api public
    #
    # ACLs for `Hyrax::Resource` models
    #
    # Allows managing `Hyrax::Permission` entries referring to a specific
    # `Hyrax::Resource.
    #
    class AccessControlList
      DISCOVER = :discover
      EDIT     = :edit
      READ     = :read

      ##
      # @!attribute [rw] resource
      #   @return [Valkyrie::Resource]
      # @!attribute [r] persister
      #   @return [#save]
      # @!attribute [r] query_service
      #   @return [#find_inverse_references_by]
      attr_reader :persister, :query_service
      attr_accessor :resource

      ##
      # @param resource [Valkyrie::Resource]
      # @param persister [#save] defaults to the configured Hyrax persister
      # @param query_service [#find_inverse_references_by] defaults to the
      #   configured Hyrax query service
      def initialize(resource:, persister:, query_service:)
        self.resource  = resource
        @persister     = persister
        @query_service = query_service
      end

      ##
      # @api public
      #
      # @param permission [Hyrax::Permission]
      #
      # @return [Boolean]
      def <<(permission)
        permission.access_to = resource.id

        change_set.permissions += [permission]

        true
      end
      alias add <<

      ##
      # @api public
      #
      # @param permission [Hyrax::Permission]
      #
      # @return [Boolean]
      def delete(permission)
        change_set.permissions -= [permission]

        true
      end

      ##
      # @api public
      #
      # @example
      #    user = User.find('user_id')
      #
      #    acl.grant(:read).to(user)
      def grant(mode)
        ModeGrant.new(self, mode)
      end

      ##
      # Discover grant
      # @agent [Hyrax::Acl::Agent] agent
      def has_discover?(agent:)
        has_grant?(mode: DISCOVER, agent: agent)
      end

      ##
      # Read grant
      # @agent [Hyrax::Acl::Agent] agent
      def has_read?(agent:)
        has_grant?(mode: READ, agent: agent)
      end

      ##
      # Edit grant
      # @agent [Hyrax::Acl::Agent] agent
      def has_edit?(agent:)
        has_grant?(mode: EDIT, agent: agent)
      end

      ##
      # Edit grant
      # @agent [Hyrax::Acl::Agent] agent
      def has_grant?(mode:, agent:)
        permissions.any? do |permission|
          permission.mode ==  mode && permission.agent == agent.agent_key
        end
      end

      ##
      # @api public
      #
      # @return [Boolean]
      def pending_changes?
        change_set.changed?
      end

      ##
      # @api public
      #
      # @return [Set<Hyrax::Permission>]
      def permissions
        Set.new(change_set.permissions)
      end

      ##
      # @api public
      #
      # @example
      #    user = User.find('user_id')
      #
      #    acl.revoke(:read).from(user)
      def revoke(mode)
        ModeRevoke.new(self, mode)
      end

      ##
      # @api public
      #
      # Saves the ACL for the resource, by saving each permission policy
      #
      # @return [Boolean]
      def save
        return true unless pending_changes?

        change_set.sync
        persister.save(resource: change_set.resource)
        yield self if block_given?
        @change_set = nil

        true
      end

      private

      ##
      # @api private
      def access_control_model
        AccessControl.for(resource: resource, query_service: query_service)
      end

      ##
      # @api private
      def change_set
        @change_set ||= ChangeSet.for(access_control_model)
      end

      ##
      # @abstract
      # @api private
      class ModeEditor
        def initialize(acl, mode)
          @acl  = acl
          @mode = mode.to_sym
        end

        private

        ##
        # Returns the identifier used by ACLs to identify agents.
        #
        # This defaults to the `:agent_key`, but if that method doesn’t exist,
        # `:user_key` will be used as a fallback.
        def id_for(agent:)
          key = agent.try(:agent_key) || agent.user_key
          key.to_s
        end
      end

      ##
      # @api private
      #
      # A short-term memory object for the permission granting DSL. Use with
      # method chaining, as in: `acl.grant(:edit).to(user)`.
      class ModeGrant < ModeEditor
        ##
        # @api public
        # @return [Hyrax::AccessControlList]
        def to(user_or_group)
          agent_id = id_for(agent: user_or_group)

          @acl << Hyrax::Acl::Permission.new(access_to: @acl.resource.id, agent: agent_id, mode: @mode)
          @acl
        end
      end

      ##
      # @api private
      #
      # A short-term memory object for the permission revoking DSL. Use with
      # method chaining, as in: `acl.revoke(:edit).from(user)`.
      class ModeRevoke < ModeEditor
        ##
        # @api public
        # @return [Hyrax::AccessControlList]
        def from(user_or_group)
          permission_for_deletion = @acl.permissions.find do |p|
            p.mode == @mode &&
              p.agent.to_s == id_for(agent: user_or_group)
          end

          @acl.delete(permission_for_deletion) if permission_for_deletion
          @acl
        end
      end
    end
  end
end
