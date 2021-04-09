# frozen_string_literal: true

require "earl"
require "socket"

module Earl
  # :nodoc:
  class BasicServer
    include Earl::Agent
    include Earl::Logger

    SERVER_EXCEPTIONS = [
      Errno::ECONNABORTED,
      Errno::ECONNRESET,
      Errno::ETIMEDOUT,
      Errno::EPIPE,
      Errno::EBADF,
      IOError,
      OpenSSL::SSL::SSLError,
      SocketError,
    ]

    def handle(client)
      Fiber.schedule do
        @handler.call(client)
      rescue *SERVER_EXCEPTIONS
        # silence connection issues
      rescue => ex
        log.exception(ex)
      ensure
        client.close
      end
    end

    def terminate
      @server&.close
      @server = nil
    end

    def reset
      @server = nil
    end

    def started?
      !@server.nil?
    end
  end
end
