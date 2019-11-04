# frozen_string_literal: true
require "minitest/autorun"
require "minitest/pride"

class Minitest::Test
  def eventually(timeout = 5)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    loop do
      Earl.sleep(0)

      begin
        yield
      rescue ex
        stopped = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise ex if (stopped - started) > timeout
      else
        break
      end
    end
  end
end
