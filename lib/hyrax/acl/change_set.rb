# frozen_string_literal: true

module Hyrax
  module Acl
    ##
    # @api private
    #
    # Build a changeset class for the given resource class. The ChangeSet will
    # have fields to match the resource class given.
    #
    # To define a custom changeset with validations, use naming convention with "ChangeSet" appended to the end
    # of the resource class name. (e.g. for BookResource, name the change set BookResourceChangeSet)
    #
    # @example
    #   Hyrax::ChangeSet(Monograph)
    def self.ChangeSet(resource_class)
      klass = (resource_class.to_s + "ChangeSet").safe_constantize || Hyrax::Acl::ChangeSet
      Class.new(klass) do
        (resource_class.fields - resource_class.reserved_attributes).each do |field|
          property field, default: nil
        end

        ##
        # @return [String]
        def self.inspect
          return "Hyrax::Acl::ChangeSet(#{model_class})" if name.blank?
          super
        end
      end
    end

    class ChangeSet < Valkyrie::ChangeSet
      ##
      # @api public
      #
      # Factory for resource ChangeSets
      #
      # @example
      #   access_control  = AccessControl.new
      #   change_set = Hyrax::ChangeSet.for(access_control)
      #
      #   change_set.permissions = my_permissions
      #   change_set.sync
      #   monograph.permissions # =>
      #
      def self.for(resource)
        Hyrax::Acl::ChangeSet(resource.class).new(resource)
      end
    end
  end
end
