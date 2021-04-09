# frozen_string_literal: true

require "earl/errors"

module Earl
  module Agent
    # Finite state machine that maintains the status of an `Agent`.
    #
    # :nodoc:
    class State
      def initialize(agent)
        @agent = agent
        @status = :starting
      end

      def value
        @status
      end

      def can_transition?(new_status) # rubocop:disable Metrics/CyclomaticComplexity
        case @status
        when :starting
          new_status == :running
        when :running
          new_status == :stopping || new_status == :crashed
        when :stopping
          new_status == :stopped || new_status == :crashed
        when :stopped, :crashed
          new_status == :recycling
        when :recycling
          new_status == :starting
        else
          false
        end
      end

      def transition(new_status)
        if can_transition?(new_status)
          Earl.logger.debug(@agent) { "transition from=#{@status} to=#{new_status}" }
          @status = new_status
        else
          raise TransitionError.new("can't transition agent state from #{@status} to #{new_status}")
        end
      end
    end
  end
end
