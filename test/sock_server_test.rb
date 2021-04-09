# frozen_string_literal: true
require "test_helper"
require "earl/sock_server"

module Earl
  class SockServerTest < Minitest::Test
    class EchoServer < Earl::SockServer
      def handle(client)
        while line = client.gets
          client << line
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

      #ssl_cert = File.expand_path("../ssl.crt", __dir__)
      #ssl_key = File.expand_path("../ssl.key", __dir__)

      #server.add_unix_listener(path)
      server.add_tcp_listener("127.0.0.1", 9494)
      #server.add_listener("ssl://127.0.0.1:9595?cert=#{ssl_cert}&key=#{ssl_key}&mode=none")

      n = 2

      with_scheduler do
        server.schedule
        eventually { assert server.started? }

        done = Channel.new

        #Fiber.schedule do
        #  UNIXSocket.open(path) do |socket|
        #    n.times do |i|
        #      socket << "hello julien #{i} (UNIX)\n"
        #      socket.flush
        #      assert_equal "hello julien #{i} (UNIX)\n", socket.gets
        #    end

        #    done.send(:unix)
        #  end
        #end

        Fiber.schedule do
          TCPSocket.open("127.0.0.1", 9494) do |socket|
            # use buffer to send/read messages otherwise it takes seconds to run:
            n.times { |i| socket << "hello julien #{i} (TCP)\n" }
            socket.flush
            n.times { |i| assert_equal "hello julien #{i} (TCP)\n", socket.gets }

            done.send(:tcp)
          end
        end

        #Fiber.schedule do
        #  tcp_socket = TCPSocket.new("127.0.0.1", 9595)

        #  socket = OpenSSL::SSL::SSLSocket.new(tcp_socket)
        #  socket.sync_close = true
        #  socket.connect # SSL client handshake

        #  n.times { |i| socket << "hello julien #{i} (SSL)\n" }
        #  socket.flush
        #  n.times { |i| assert_equal "hello julien #{i} (SSL)\n", socket.gets }

        #  done.send(:ssl)
        #ensure
        #  if socket
        #    socket.close
        #  else
        #    tcp_socket.close
        #  end
        #end

        1.times { done.receive }

        server.stop
      end
    end
  end
end
