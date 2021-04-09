# frozen_string_literal: true

require "openssl"
require "earl/basic_server"

module Earl
  # :nodoc:
  class SSLServer < BasicServer
    def initialize(host, port, context, backlog = nil, &block)
      @host = host
      @port = port
      @backlog = backlog
      @handler = block

      unless context.session_id_context
        prng = ::Random.new($0.hash)
        session_id = prng.bytes(16).unpack1("H*")
        context.session_id_context = session_id
      end

      @context = context.tap(&:setup)
    end

    def call
      @server = ::TCPServer.new(@host, @port)
      @server.listen(@backlog) if @backlog
      log.info { "started ssl server host=#{@host} port=#{@port}" }

      loop do
        socket, _ = @server.accept
        log.debug { "incoming ssl connection" }
        handle(socket)
      rescue *SERVER_EXCEPTIONS
        # silence connection issues
      end
    end

    def handle(socket)
      ssl_client = OpenSSL::SSL::SSLSocket.new(socket, @context)
      ssl_client.sync_close = true

      Fiber.schedule do
        ssl_client.accept # SSL server handshake
        @handler.call(ssl_client)
      rescue *SERVER_EXCEPTIONS
        # silence connection issues
      rescue => ex
        log.exception(ex)
      ensure
        if ssl_client
          ssl_client.close
        else
          socket.close
        end
      end
    end
  end
end
