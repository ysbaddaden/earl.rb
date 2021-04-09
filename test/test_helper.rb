# frozen_string_literal: true
require "minitest/autorun"
require "minitest/pride"
# require "kernel/sync"
require "earl"

class Minitest::Test
  def eventually(timeout = 2)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      sleep(0)
      yield
    rescue Minitest::Assertion => e
      stopped = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise e if (stopped - started) > timeout
      retry
    else
      return
    end
  end

  def with_scheduler
    #if defined?(Async)
    #  Async do |reactor|
    #    yield
    #  ensure
    #    reactor.stop
    #  end
    #elsif defined?(Evt)
    #  scheduler = Evt::Epoll.new
    #  Fiber.set_scheduler(scheduler)
    #  Fiber.schedule { yield }
    #  scheduler.run
    #  Fiber.set_scheduler(nil)
    #end

    scheduler = Earl::Scheduler.new
    Fiber.set_scheduler(scheduler)
    Fiber.schedule { yield }
    scheduler.run
    # Fiber.set_scheduler(nil)
  end
end

# TODO: find a solution to create an Async::Reactor that will run the logger
# actor for the duration of tests... that minitest will eventually run in an
# at_exit block. For the time being, we bypass the actor and write directly to
# STDOUT (which is fine because it's not multithreaded).
Earl.logger.level = Earl::Logger::DEBUG
Earl.logger.sync = true
