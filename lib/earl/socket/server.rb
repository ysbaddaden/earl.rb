# frozen_string_literal: true
require "earl"

module Earl::Socket
  # :nodoc:
  class Server
    include Earl::Agent
    include Earl::Logger

    def handle(client)
      Async do
        @handler.call(client)
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
