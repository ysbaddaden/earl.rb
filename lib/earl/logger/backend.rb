# frozen_string_literal: true

module Earl
  module Logger
    class Backend
      def write(severity, agent, time, message) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError.new("#{self.class.name}#write must be implemented")
      end
    end
  end
end
