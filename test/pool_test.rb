# frozen_string_literal: true
require "test_helper"

module Earl
  class PoolTest < Minitest::Test
    class Worker
      include Earl::Artist

      def handle(message)
        log.info "received #{message}"
        sleep(0)
        raise "chaos monkey" if rand(0..9) == 1
      end
    end

    def test_pool
      with_scheduler do
        pool = Pool.new(Worker, 5)

        Fiber.schedule do
          999.times { |i| pool.send(i) }
          pool.stop
        end

        pool.start
      end
    end
  end
end
