# frozen_string_literal: true
require "earl"
require "earl/sock_server"

class EchoServer < Earl::SockServer
  def handle(client)
    while line = client.gets
      client << line
      client.flush
    end
  end
end

server = EchoServer.new
server.add_tcp_listener("::", 9494)
server.add_unix_listener("/tmp/earl_echo_server_#{Process.pid}.sock")

certificate = File.expand_path("../ssl.crt", __dir__)
private_key = File.expand_path("../ssl.key", __dir__)
server.add_listener("ssl://[::]:9595?cert=#{certificate}&key=#{private_key}&mode=none")

Earl.logger.level = Earl::Logger::DEBUG
Earl.logger.sync = true

Async do
  Earl.application.monitor(server)
  Earl.application.schedule
end
