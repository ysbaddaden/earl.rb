# frozen_string_literal: true
require "async/io/ssl_socket"
require "earl/socket/server"

module Earl::Socket
  # :nodoc:
  class SSLServer < Server
    def initialize(host, port, context, backlog = nil, &block)
      @host = host
      @port = port
      @context = context.tap(&:setup)
      @backlog = backlog
      @handler = block
    end

    def call
      @server = Async::IO::TCPServer.wrap(@host, @port)
      @server.listen(@backlog) if @backlog
      log.info { "started ssl server host=#{@host} port=#{@port}" }

      loop do
        socket, _ = tcp_server.accept
        log.debug { "incoming ssl connection" }
        handle(socket)
      end
    rescue Async::Wrapper::Cancelled
    end

    def handle(socket)
      client = Async::IO::SSLSocket.new(socket, @context)

      Async do
        client.accept # SSL handshake
        @handler.call(client)
      rescue => ex
        log.exception(ex)
      ensure
        client.close
      end
    end
  end
end
