require "earl/agent"
require "earl/mailbox"

module Earl
  module Artist
    include Agent
    include Mailbox

    def call
      while message = receive?
        handle(message)
      end
    end

    def handle(message)
      raise NotImplementedError.new("#{self.class.name}#handle(message) must be implemented")
    end
  end
end
