# frozen_string_literal: true

module Hyrax
  class Agent
    attr_reader :name

    def initialize(name)
      @name = name
    end

    ##
    # @return [String] a local identifier in ACL
    #   data
    def agent_key
      name
    end
  end
end
