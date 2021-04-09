# frozen_string_literal: true

require "earl/basic_server"

module Earl
  # :nodoc:
  class TCPServer < BasicServer
    def initialize(host, port, backlog = nil, &block)
      @host = host
      @port = port
      @backlog = backlog
      @handler = block
    end

    def call
      @server = ::TCPServer.new(@host, @port)
      @server.listen(@backlog) if @backlog
      log.info { "started tcp server host=#{@host} port=#{@port}" }

      loop do
        client, = @server.accept
        log.debug { "incoming tcp connection" }
        handle(client)
      rescue *SERVER_EXCEPTIONS
        break
      end
    end
  end
end
