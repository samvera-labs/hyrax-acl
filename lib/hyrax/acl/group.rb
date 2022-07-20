# frozen_string_literal: true
module Hyrax
  module Acl
    class Group < Agent
      DEFAULT_NAME_PREFIX = 'group/'

      def self.name_prefix
        DEFAULT_NAME_PREFIX
      end

      ##
      # @return [Hyrax::Group]
      def self.from_agent_key(key)
        new(key.delete_prefix(name_prefix))
      end

      def initialize(name)
        super
      end

      ##
      # @return [String] a local identifier for this group; for use (e.g.) in ACL
      #   data
      def agent_key
        self.class.name_prefix + name
      end

      ##
      # @return [Boolean]
      def ==(other)
        other.class == self.class && other.name == name
      end
    end
  end
end
