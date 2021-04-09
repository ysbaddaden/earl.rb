# frozen_string_literal: true

require "earl/basic_server"

module Earl
  # :nodoc:
  class UNIXServer < BasicServer
    def initialize(path, mode, backlog = nil, &block)
      @path = path
      @mode = mode
      @backlog = backlog
      @handler = block
    end

    def call
      @server = ::UNIXServer.new(@path)
      @server.listen(@backlog) if @backlog
      File.chmod(@path, @mode) if @mode
      log.info { "started unix server path=#{@path}" }

      loop do
        client, = @server.accept
        log.debug { "incoming unix connection" }
        handle(client)
      rescue *SERVER_EXCEPTIONS
        # silence connection issues
      end
    end
  end
end
