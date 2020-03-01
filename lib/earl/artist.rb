# frozen_string_literal: true

module Earl
  module Artist
    include Agent
    include Logger
    include Mailbox

    def call
      while message = receive?
        handle(message)
      end
    end

    def handle(message) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError.new("#{self.class.name}#handle(message) must be implemented")
    end
  end
end
