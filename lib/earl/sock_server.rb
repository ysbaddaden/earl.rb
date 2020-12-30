require "uri"
require "earl/socket/ssl_server"
require "earl/socket/tcp_server"
require "earl/socket/unix_server"

module Earl
  # A stream socket server.
  #
  # - Binds to and listens on many interfaces and ports.
  # - Servers are spawned in a dedicated `Fiber` then supervised.
  # - Incoming connections are handled in their own `Fiber` that runs
  #   `#call(client)` and are eventually closed when the method returns or
  #   raised.
  class SockServer < Supervisor
    # Called in a dedicated `Fiber` when a server receives a connection.
    # Connections are closed when the method returns or raised.
    def handle(client)
      raise NotImplementedError
    end

    # Adds a TCP server.
    def add_tcp_listener(host, port, backlog: nil)
      server = Socket::TCPServer.new(host, port, backlog) do |client|
        handle(client)
      end
      monitor(server)
    end

    # Adds a TCP server with transparent SSL handling.
    def add_ssl_listener(host, port, ssl_context, backlog: nil)
      server = Socket::SSLServer.new(host, port, ssl_context, backlog) do |client|
        handle(client)
      end
      monitor(server)
    end

    # Adds an UNIX server.
    def add_unix_listener(path, mode: nil, backlog: nil)
      server = Socket::UNIXServer.new(path, mode, backlog) do |client|
        handle(client)
      end
      monitor(server)
    end

    # Adds a server based on an URI definition. For example:
    #
    # ```
    # server.add_listener("unix:///tmp/earl.sock")
    # server.add_listener("tcp://[::]:9292")
    # server.add_listener("ssl://10.0.3.1:443/?cert=ssl/server.crt&key=ssl/server.key")
    # ```
    def add_listener(uri)
      uri = URI.parse(uri) if uri.is_a?(String)
      params = Hash[URI.decode_www_form(uri.query || "")]

      case uri.scheme
      when "tcp"
        host, port = parse_host(uri)
        add_tcp_listener(host, port)
      when "ssl"
        host, port = parse_host(uri)
        add_ssl_listener(host, port, build_ssl_context(params))
      when "unix"
        mode = params["mode"].to_i ? params["mode"].to_i(8) : nil
        add_unix_listener(uri.path, mode: mode)
      else
        raise ArgumentError.new("unsupported socket type: #{uri}")
      end
    end

    def started?
      running? && @agents.all? do |agent|
        if agent.respond_to?(:started?)
          agent.started? # either Earl::Socket::TCPServer, Earl::Socket::UNIXServer or Earl::Socket::SSLServer
        else
          agent.running? # should be unreachable
        end
      end
    end

    private

    def parse_host(uri)
      port = uri.port
      raise ArgumentError.new("please specify a port to listen to") unless port

      host = uri.host
      raise ArgumentError.new("please specify a host or ip to listen to") unless host

      # remove ipv6 brackets
      if host.start_with?('[') && host.end_with?(']')
        host = host[1..-2]
      end

      [host, port]
    end

    def build_ssl_context(params)
      raise ArgumentError.new("please specify the SSL certificate via 'cert'") unless params["cert"]
      raise ArgumentError.new("please specify the SSL key via 'key'") unless params["key"]

      ctx = OpenSSL::SSL::SSLContext.new
      ctx.min_version = ssl_min_version
      ctx.ciphers = ssl_ciphers
      ctx.ecdh_curves = ssl_curves

      case params["verify_mode"]
      when "peer"
        ctx.verify_mode = OpenSSL::VERIFY_PEER
      when "force-peer"
        ctx.verify_mode = OpenSSL::VERIFY_FAIL_IF_NO_PEER_CERT
      when "none"
        ctx.verify_mode = OpenSSL::VERIFY_NONE
      end

      crt = OpenSSL::X509::Certificate.new(File.read(params["cert"]))
      key = OpenSSL::PKey.read(File.read(params["key"]))

      if params["ca"]
        ca = OpenSSL::X509::Certificate.new(File.read(params["ca"]))
        ctx.add_certificate(crt, key, [ca])
      elsif ctx.verify_mode == OpenSSL::VERIFY_PEER || ctx.verify_mode == OpenSSL::VERIFY_FAIL_IF_NO_PEER_CERT
        raise ArgumentError.new("please specify the SSL ca via 'ca'")
      else
        ctx.add_certificate(crt, key)
      end

      ctx
    end

    def ssl_min_version
      # see Mozilla Security/Server Side TLS (intermediate level)
      OpenSSL::SSL::TLS1_2_VERSION
    end

    def ssl_ciphers
      # see Mozilla Security/Server Side TLS (intermediate level)
      %w[
        TLS_AES_128_GCM_SHA256
        TLS_AES_256_GCM_SHA384
        TLS_CHACHA20_POLY1305_SHA256

        ECDHE-ECDSA-AES128-GCM-SHA256
        ECDHE-RSA-AES128-GCM-SHA256
        ECDHE-ECDSA-AES256-GCM-SHA384
        ECDHE-RSA-AES256-GCM-SHA384
        ECDHE-ECDSA-CHACHA20-POLY1305
        ECDHE-RSA-CHACHA20-POLY1305
        DHE-RSA-AES128-GCM-SHA256
        DHE-RSA-AES256-GCM-SHA384

        !RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS
      ]
    end

    def ssl_curves
      # see Mozilla Security/Server Side TLS (intermediate level)
      %w[X25519 P-256 P-384] # P-256=prime256v1 ; P-384=secp384r1
    end
  end
end
