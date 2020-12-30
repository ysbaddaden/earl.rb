# frozen_string_literal: true
require "async/io/tcp_socket"
require "earl/socket/server"

module Earl::Socket
  # :nodoc:
  class TCPServer < Server
    def initialize(host, port, backlog = nil, &block)
      @host = host
      @port = port
      @backlog = backlog
      @handler = block
    end

    def call
      @server = Async::IO::TCPServer.wrap(@host, @port)
      @server.listen(@backlog) if @backlog
      log.info { "started tcp server host=#{@host} port=#{@port}" }

      loop do
        client, = @server.accept
        log.debug { "incoming tcp connection" }
        handle(client)
      end
    rescue Async::Wrapper::Cancelled
    end
  end
end
