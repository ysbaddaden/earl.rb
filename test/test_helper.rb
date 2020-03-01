# frozen_string_literal: true
require "minitest/autorun"
require "minitest/pride"
require "kernel/sync"
require "earl"

class Minitest::Test
  def eventually(timeout = 5)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      Earl.sleep(0.001)
      yield
    rescue Minitest::Assertion => e
      stopped = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise e if (stopped - started) > timeout
      retry
    else
      return
    end
  end
end

# TODO: find a solution to create an Async::Reactor that will run the logger
# actor for the duration of tests... that minitest will eventually run in an
# at_exit block. For the time being, we bypass the actor and write directly to
# STDOUT (which is fine because it's not multithreaded).
Earl.logger.level = Earl::Logger::SILENT
Earl.logger.sync = true
