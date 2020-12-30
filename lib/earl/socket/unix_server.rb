# frozen_string_literal: true
require "async/io/unix_socket"
require "earl/socket/server"

module Earl::Socket
  # :nodoc:
  class UNIXServer < Server
    def initialize(path, mode, backlog = nil, &block)
      @path = path
      @mode = mode
      @backlog = backlog
      @handler = block
    end

    def call
      @server = Async::IO::UNIXServer.wrap(@path)
      @server.listen(@backlog) if @backlog
      File.chmod(@path, @mode) if @mode
      log.info { "started unix server path=#{@path}" }

      loop do
        client, = @server.accept
        p client

        log.debug { "incoming unix connection" }
        handle(client)
      end
    rescue Async::Wrapper::Cancelled
    end
  end
end
