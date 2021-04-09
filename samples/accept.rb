# frozen_string_literal: true

require "socket"
require "earl/scheduler"

Fiber.set_scheduler(Earl::Scheduler.new)

Fiber.schedule do
  server = TCPServer.new("127.0.0.1", 9393)
  done = false

  #thread = Thread.new do
  Fiber.schedule do
    p :accepting
    server.sysaccept
    p :accepted
  rescue IOError, Errno::EBADF
    done = true
  end

  Fiber.schedule do
    server.close
    p :closed, server
  end

  # waiting for server to be closed...
  until done
    sleep(0)
  end
  # thread.join

  p :exit
end
