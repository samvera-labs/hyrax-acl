# frozen_string_literal: true

module Hyrax
  module Acl
    DISCOVER = :discover
    EDIT     = :edit
    READ     = :read

    ##
    # @api public
    #
    # ACLs for `Hyrax::Resource` models
    #
    # Allows managing `Hyrax::Permission` entries referring to a specific
    # `Hyrax::Resource.
    #
    class AccessControlList
      ##
      # @!attribute [r] access_control
      #   @return [Hyax:Acl:AccessControl]
      attr_reader :access_control

      ##
      # @api public
      #
      # @param :access_control [Hyax:Acl:AccessControl]
      def initialize(access_control:)
        @access_control = access_control
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
      # @return [Set<Hyrax::Permission>]
      def permissions
        access_control.permissions
      end
    end
  end
end
