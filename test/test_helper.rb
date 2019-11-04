# frozen_string_literal: true
require "minitest/autorun"
require "minitest/pride"

class Minitest::Test
  def eventually(timeout = 5)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      Earl.sleep(0)
      yield
    rescue Minitest::Assertion => ex
      stopped = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise ex if (stopped - started) > timeout
      retry
    else
      return
    end
  end
end
