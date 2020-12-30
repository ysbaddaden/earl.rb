# frozen_string_literal: true
require "test_helper"
require "earl/sock_server"

module Earl
  class SockServerTest < Minitest::Test
    class EchoServer < Earl::SockServer
      def handle(client)
        while line = client.gets
          client << "#{line}\n"
          client.flush
        end
      end
    end

    def path
      "/tmp/earl_test_#{Process.pid}.sock"
    end

    def teardown
      File.unlink(path) if File.exist?(path)
    end

    def test_add_many_listeners
      server = EchoServer.new

      #ctx = OpenSSL::SSL::SSLContext.new
      #crt = OpenSSL::X509::Certificate.new(File.read(File.expand_path("../ssl.crt", __dir__)))
      #key = OpenSSL::PKey.read(File.read(File.expand_path("../ssl.key", __dir__)))
      #ctx.add_certificate crt, key

      server.add_unix_listener(path)
      server.add_tcp_listener("127.0.0.1", 9494)
      #server.add_ssl_listener("127.0.0.1", 9595, ctx)

      Async do
        server.async
        eventually { assert server.started? }

        done = Channel.new

        Async do
          Async::IO::UNIXSocket.wrap(path) do |socket|
            999.times do |i|
              socket << "hello julien #{i} (UNIX)\n"
              socket.flush
              assert_equal "hello julien #{i} (UNIX)", socket.gets
            end
            done.send(1)
          end
        end

        Async do
          Async::IO::TCPSocket.wrap("127.0.0.1", 9494) do |socket|
            # use buffer to send/read messages otherwise it takes seconds to run:
            999.times { |i| socket << "hello julien #{i} (TCP)\n" }
            socket.flush
            999.times { |i| assert_equal "hello julien #{i} (TCP)", socket.gets }
            done.send(1)
          end
        end

        #Async do
        #  socket = Async::IO::TCPSocket.open("127.0.0.1", 9595)

        #  ctx = OpenSSL::SSL::SSLContext.new
        #  ctx.verify_mode = OpenSSL::SSL::VerifyMode::NONE
        #  socket = Async::IO::SSLSocket.new(socket, ctx)

        #  # use #read because Async::IO::SSLSocket#gets is private (?)
        #  999.times { |i| socket.puts "hello julien #{i} (SSL)" }
        #  socket.close_write
        #  message = 999.times.map { |i| "hello julien #{i} (SSL)" }.join("\n")
        #  assert_equal message, socket.read

        #  done.send(1)
        #ensure
        #  socket.close
        #end

        1.times { done.receive }

        server.stop
      end
    end
  end
end
